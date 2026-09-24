#define UNICODE
#define _UNICODE
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#define COUNT 5
#define MAX_WIN_PATH 32767

typedef struct {
    ULONGLONG size;
    wchar_t *path;
} File;

typedef struct {
    File items[COUNT];
    int count;
} Ranking;

typedef struct {
    Ranking largest;
    Ranking smallest;
    ULONGLONG files;
    ULONGLONG folders;
    ULONGLONG skipped_links;
    ULONGLONG inaccessible;
    ULONGLONG errors;
} Scan;

static wchar_t *copy_text(const wchar_t *text)
{
    size_t length = wcslen(text) + 1;
    wchar_t *copy = malloc(length * sizeof(*copy));
    if (copy != NULL) {
        memcpy(copy, text, length * sizeof(*copy));
    }
    return copy;
}

static wchar_t *join_path(const wchar_t *directory, const wchar_t *name)
{
    size_t dir_length = wcslen(directory);
    size_t name_length = wcslen(name);
    int separator = dir_length > 0 && directory[dir_length - 1] != L'\\';

    if (dir_length + separator + name_length >= MAX_WIN_PATH) {
        return NULL;
    }

    wchar_t *path = malloc((dir_length + separator + name_length + 1) * sizeof(*path));
    if (path == NULL) {
        return NULL;
    }

    memcpy(path, directory, dir_length * sizeof(*path));
    if (separator) {
        path[dir_length++] = L'\\';
    }
    memcpy(path + dir_length, name, (name_length + 1) * sizeof(*path));
    return path;
}

/* Keep each ranking sorted; only copy paths that make the top or bottom five. */
static int remember_file(Ranking *ranking, ULONGLONG size,
                         const wchar_t *path, int largest)
{
    int position = 0;
    while (position < ranking->count &&
           (largest ? size <= ranking->items[position].size
                    : size >= ranking->items[position].size)) {
        position++;
    }

    if (position == COUNT) {
        return 1;
    }

    wchar_t *copy = copy_text(path);
    if (copy == NULL) {
        return 0;
    }

    if (ranking->count == COUNT) {
        free(ranking->items[COUNT - 1].path);
    } else {
        ranking->count++;
    }

    for (int i = ranking->count - 1; i > position; --i) {
        ranking->items[i] = ranking->items[i - 1];
    }
    ranking->items[position].size = size;
    ranking->items[position].path = copy;
    return 1;
}

static void count_error(Scan *scan, DWORD error)
{
    if (error == ERROR_ACCESS_DENIED) {
        scan->inaccessible++;
    } else {
        scan->errors++;
    }
}

/* Return 0 only for a fatal allocation failure. Individual folder errors are skipped. */
static int scan_directory(const wchar_t *directory, Scan *scan)
{
    WIN32_FIND_DATAW entry;
    wchar_t *pattern = join_path(directory, L"*");
    if (pattern == NULL) {
        return 0;
    }

    scan->folders++;
    HANDLE handle = FindFirstFileW(pattern, &entry);
    free(pattern);

    if (handle == INVALID_HANDLE_VALUE) {
        DWORD error = GetLastError();
        if (error != ERROR_FILE_NOT_FOUND) {
            count_error(scan, error);
        }
        return 1;
    }

    int success = 1;
    do {
        if (wcscmp(entry.cFileName, L".") == 0 ||
            wcscmp(entry.cFileName, L"..") == 0) {
            continue;
        }

        if (entry.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) {
            scan->skipped_links++;
            continue;
        }

        wchar_t *path = join_path(directory, entry.cFileName);
        if (path == NULL) {
            success = 0;
            break;
        }

        if (entry.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
            success = scan_directory(path, scan);
        } else {
            ULONGLONG size = ((ULONGLONG)entry.nFileSizeHigh << 32) |
                              entry.nFileSizeLow;
            scan->files++;
            success = remember_file(&scan->largest, size, path, 1) &&
                      remember_file(&scan->smallest, size, path, 0);
        }

        free(path);
        if (!success) {
            break;
        }
    } while (FindNextFileW(handle, &entry));

    if (success) {
        DWORD error = GetLastError();
        if (error != ERROR_NO_MORE_FILES) {
            count_error(scan, error);
        }
    }
    FindClose(handle);
    return success;
}

static wchar_t *absolute_path(const wchar_t *input)
{
    DWORD needed = GetFullPathNameW(input, 0, NULL, NULL);
    if (needed == 0) {
        return NULL;
    }

    wchar_t *full = malloc((size_t)needed * sizeof(*full));
    if (full == NULL) {
        return NULL;
    }

    DWORD length = GetFullPathNameW(input, needed, full, NULL);
    if (length == 0 || length >= needed) {
        free(full);
        return NULL;
    }

    /* Extended paths let Windows enumerate folders beyond the old MAX_PATH limit. */
    wchar_t *result = NULL;
    if (wcsncmp(full, L"\\\\?\\", 4) == 0) {
        result = copy_text(full);
    } else if (wcsncmp(full, L"\\\\", 2) == 0) {
        result = join_path(L"\\\\?\\UNC", full + 2);
    } else if (length >= 3 && full[1] == L':' && full[2] == L'\\') {
        size_t total = (size_t)length + 5;
        result = malloc(total * sizeof(*result));
        if (result != NULL) {
            wcscpy(result, L"\\\\?\\");
            wcscat(result, full);
        }
    }

    free(full);
    return result;
}

static void print_path(const wchar_t *path)
{
    if (wcsncmp(path, L"\\\\?\\UNC\\", 8) == 0) {
        wprintf(L"\\\\%ls", path + 8);
    } else if (wcsncmp(path, L"\\\\?\\", 4) == 0) {
        wprintf(L"%ls", path + 4);
    } else {
        wprintf(L"%ls", path);
    }
}

static void print_ranking(const wchar_t *title, const Ranking *ranking)
{
    wprintf(L"\n%ls\n", title);
    for (int i = 0; i < ranking->count; ++i) {
        wprintf(L"%d. %llu bytes  ", i + 1,
                (unsigned long long)ranking->items[i].size);
        print_path(ranking->items[i].path);
        wprintf(L"\n");
    }
    if (ranking->count == 0) {
        wprintf(L"(no files found)\n");
    }
}

int wmain(int argc, wchar_t **argv)
{
    if (argc != 2) {
        fwprintf(stderr, L"Usage: filesizes.exe C:\\\n"
                         L"       filesizes.exe \"D:\\My Folder\"\n");
        return 2;
    }

    wchar_t *root = absolute_path(argv[1]);
    if (root == NULL) {
        fwprintf(stderr, L"Could not resolve the input path.\n");
        return 2;
    }

    DWORD attributes = GetFileAttributesW(root);
    if (attributes == INVALID_FILE_ATTRIBUTES ||
        !(attributes & FILE_ATTRIBUTE_DIRECTORY)) {
        fwprintf(stderr, L"The input must be an accessible folder or drive.\n");
        free(root);
        return 2;
    }

    Scan scan = {0};
    wprintf(L"Scanning ");
    print_path(root);
    wprintf(L" ...\n");

    int success = scan_directory(root, &scan);
    if (success) {
        print_ranking(L"5 LARGEST FILES", &scan.largest);
        print_ranking(L"5 SMALLEST FILES", &scan.smallest);
        wprintf(L"\nFiles: %llu | Folders: %llu | Skipped reparse points: %llu"
                L" | Access denied: %llu | Other errors: %llu\n",
                (unsigned long long)scan.files,
                (unsigned long long)scan.folders,
                (unsigned long long)scan.skipped_links,
                (unsigned long long)scan.inaccessible,
                (unsigned long long)scan.errors);
    } else {
        fwprintf(stderr, L"Scan stopped: allocation or path limit reached.\n");
    }

    for (int i = 0; i < scan.largest.count; ++i) {
        free(scan.largest.items[i].path);
    }
    for (int i = 0; i < scan.smallest.count; ++i) {
        free(scan.smallest.items[i].path);
    }
    free(root);
    return !success || scan.inaccessible || scan.errors ? 1 : 0;
}
