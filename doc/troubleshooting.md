## Troubleshooting

If you encounter an error, use the tables below to find its meaning and a suggested fix. Messages are quoted as they appear, with variable parts in `<angle brackets>`. Command-line errors appear in Terminal; in Python, the message appears in the exception. Installation problems are covered in the [installation guide](installation.md), which ends with its own troubleshooting table.

In messages, `query` means the table whose records receive candidates (table B by default), and `doc` means the table the candidates come from (table A by default). In a deduplication both are the one table. [How `sparkly_lite` works](how-it-works.md#the-top-k-and-the-direction) describes the direction.

### The command line

You may see one of these messages if the command is missing an argument or contains an invalid argument. Check the command against the suggested fix before running it again.

| What you see | What it means | What to do |
|---|---|---|
| `sparkly-lite block: error: no table given.` | No table was named. | Name table A and table B, or table A and `--dedup`. |
| `sparkly-lite block: error: only one table given (<file>), so there is nothing to block it against.` | One table was named, without `--dedup`. | Add table B, or add `--dedup` to find the duplicates in table A. |
| `sparkly-lite block: error: --dedup searches a single table against itself, but two tables were given (<file A> and <file B>).` | `--dedup` was given with two tables. | Leave out table B to find the duplicates in table A, or leave out `--dedup` to block the two tables. |
| `sparkly-lite block: error: argument --format: invalid choice: '<name>' (choose from parquet, csv, tsv, jsonl)` | The output format is not one of the four. | Use one of the four. |
| `sparkly-lite block: error: argument --tokenizer: invalid choice: '<name>' (choose from word, trigram, hybrid, ngram)` | The tokenizer is not one of these. | Use `word`, `trigram` or `hybrid`. `ngram` is an older name for `trigram`. |
| `sparkly-lite block: error: the column names after --columns are separated by spaces; separate them with commas, as in --columns <names>` | The names given to `--columns` are separated by spaces, so all but the first would be read as other arguments. | Separate the names with commas, as the message shows. |

### Reading the tables

If `sparkly_lite` cannot read or validate an input table, gold set, or candidate set, you may see one of these messages.

| What you see | What it means | What to do |
|---|---|---|
| `no such file: <path>` | No file exists at the path. | Check the path. A relative path starts from the current directory, so run the tutorial's commands, and start Jupyter, from the `sparkly_lite` directory. |
| `unrecognized extension '<ext>' for <file>. Supported: .parquet/.pq, .csv/.txt, .tsv, .json/.jsonl/.ndjson (or pass a pandas/Polars DataFrame or pyarrow Table).` | The file is not in a format `sparkly_lite` reads. | Convert the file to one of these formats, for example a spreadsheet to CSV. |
| `unsupported source type '<type>'; pass a file path, pandas/Polars DataFrame, or pyarrow Table` | From Python, a table was given as another kind of object. | Pass a path, a DataFrame or a pyarrow Table. |
| `no id column '_id' in columns [...]; name the id column with id_col= (--id-col on the command line), or pass id_col='_rid' to number the rows 0..n-1` | The table has no column `_id`. | Name the id column with `--id-col`, or number the rows with `--id-col _rid`. |
| `id_col '<name>' not in columns [...]` | `--id-col` names a column that the table does not have. | Use one of the names listed. |
| `id column '<name>' (<how>) is not a valid id column — an id must be present on every row and unique.` | Some rows have no id, or two rows have the same id. The lines that follow the message give the counts and the repeated values. | Fix the ids, name a column of unique values with `--id-col`, or number the rows with `--id-col _rid`. |
| `<what> has ids that are not whole numbers, such as '<value>'. Ids are whole numbers, 0 or more. To number the rows of a table keyed by strings, and its gold set, see 'Tables keyed by strings' in the technical guide.` | The ids of `<what>`, which is `table A`, `table B`, `the gold set` or `the candidate set`, include a value that is not a whole number, such as a product code. | Use `--id-col _rid` for the tables, or convert the tables and the gold set, as the section [Tables keyed by strings](technical-guide.md#tables-keyed-by-strings) of the technical guide describes. |
| `<what> has negative ids, such as <id>. Ids are whole numbers, 0 or more.` | Some ids of `<what>` are below 0. | Renumber the ids from 0, and map the gold set to the new ids. |
| `<what> has missing ids (<n> of <total>)` | Some ids of `<what>` are empty, as when a gold set converted from codes holds a code that is not in its table. | Remove the pairs with an empty id, or correct their codes and convert the gold set again. |
| `<what> has ids above 9,223,372,036,854,775,807, such as '<value>'` | Some ids of `<what>` are too large to be stored as 64-bit integers. | Renumber the ids from 0, as the section [Tables keyed by strings](technical-guide.md#tables-keyed-by-strings) of the technical guide describes. |
| `requested column(s) [...] not found in this table; available columns: [...]` | `--columns` names a column that the table does not have. | Use the names listed. The names are case-sensitive. |
| `no blocking columns in this table (columns: [...]); pass columns=[...] to choose which column(s) to block on` | The table holds only id columns. | Name the columns to block on with `--columns`. |
| `packed text is <n> bytes, above the 4 GB limit per table side; split the table or block on fewer columns` | The joined text of the blocking columns of one table is 4 GB or more. | Block on fewer columns, or block the table in parts. A run in parts gives slightly different scores, because each part has its own statistics. |
| `gold must have at least two id columns, found [...]` | The gold file has fewer than two columns. | Give a gold file with the IDs from table A in one column and the IDs from table B in the other. |
| `candidates must have the columns id1 and id2, found [...]` | The candidate set given to `evaluate` has no columns `id1` and `id2`. | Give a file that `--out` or `out=` wrote, or a table with these two columns. |

### The options

If an option is missing or invalid, you may see one of these messages when `sparkly_lite` checks the options, before blocking begins.

| What you see | What it means | What to do |
|---|---|---|
| `k must be >= 1, got <k>` | K is below 1. | Use a K from 1 to 128. |
| `k must be <= 128 (the engine's top-K limit), got <k>` | K is above 128. | Use a K from 1 to 128. |
| `direction must be 'a2b' or 'b2a', got '<value>'` | From Python, `direction` is not one of the two. | Use `'b2a'`, the default, or `'a2b'`. |
| `tokenizer must be 'word', 'trigram', or 'hybrid', got '<value>'` | From Python, `tokenizer` names an unknown tokenizer. | Use one of the three. |
| `columns='<text>' names no column; name the columns to block on, separated by commas, as in 'title,authors'` | `--columns` or `columns` holds only commas and spaces. | Name the columns to block on, as in `--columns title,authors`. |
| `unknown option(s): [...]; valid options: [...]` | A keyword given to `block` is not an option. | Use the names listed. `--k1` is `bm25_k1` in Python, and `--b-param` is `bm25_b`. |
| `block(): table_a is required` | `block` was called without table A. | Pass table A. |

### The row limit

| What you see | What it means | What to do |
|---|---|---|
| `the <side> table has <n> rows; this version handles up to 3,000,000 rows per side. Try a smaller sample.` | A table has more than 3,000,000 rows, and the run raised `LimitError`. `<side>` is `doc` for table A and `query` for table B, by default. | Block a sample or a part of the table. For larger tables, contact [our team](mailto:hello@relixa.ai). |

### Saving the candidates

If you save candidates using `--out` or `out=`, you may encounter one of these messages. Invalid output formats are detected before blocking begins; file or disk problems may occur when the output is written.

| What you see | What it means | What to do |
|---|---|---|
| `<path>: unknown extension '<ext>'; candidates are written as .parquet, .csv, .tsv or .jsonl, or with format= one of [...]` | The extension of the output file names no format. | Use one of the four extensions, or name the format with `--format`. |
| `<path>: format='<format>' does not match the extension '<ext>'; name the file for the format, or leave out format=` | The extension and `--format` name different formats. | Rename the file, or leave out `--format`. |
| `format must be one of [...], got '<value>'` | From Python, `format` is not one of the four. | Use one of the names listed. |
| `[Errno 2] Failed to open local file '<path>.partial-<n>'. Detail: [errno 2] No such file or directory` | The directory of the output file does not exist. | Create the directory, or name a file in a directory that exists. |
| `blocking failed; check that <path> can be written and that the disk has room` | The candidates could not be written to disk. | Free some disk space, or check that the directory can be written. |

### Starting `sparkly_lite`

If `sparkly_lite` cannot start, check whether the message you see is listed below.

| What you see | What it means | What to do |
|---|---|---|
| `sparkly_lite requires macOS on Apple Silicon (arm64); this is <system>/<machine>.` | The machine is not a Mac with Apple silicon. | Run `sparkly_lite` on a Mac with Apple silicon. |
| `sparkly_lite could not start on this machine; it needs an Apple Silicon Mac (M1 or newer) with macOS 11 or later` | The Mac does not meet the requirements. | Update macOS to version 11 or later, on a Mac with Apple silicon. |
| `sparkly_lite is not installed completely: <path> is missing. Run 'bash install.sh' again in the sparkly_lite folder.` | A file of the installation is missing. | Run `bash install.sh` again from the `sparkly_lite` directory. |
| `macOS did not allow sparkly_lite's library to load:` | macOS refused to load a file of `sparkly_lite`. This happens when an installed `sparkly_lite` directory is copied from another Mac. | Run `bash install.sh` again from the `sparkly_lite` directory, which installs fresh copies of the files. |

### Python and the notebook

| What you see | What it means | What to do |
|---|---|---|
| `AttributeError: module 'sparkly_lite' has no attribute '<name>'` | The name is not part of `sparkly_lite`. When a public name is close to it, the message ends with ` — did you mean '<name>'?`. | Use the name suggested. The [technical guide](technical-guide.md) lists every public name. |
| `zsh: command not found: jupyter` | The environment is not active, or Jupyter is not installed. | Run `source .venv/bin/activate`, then `pip install notebook`. |
| `ModuleNotFoundError: No module named 'sparkly_lite'` | The notebook runs a Python other than the one of the `.venv` directory. | Stop Jupyter with Ctrl-C, run `source .venv/bin/activate`, and start Jupyter again with `jupyter notebook`. |
| `ModuleNotFoundError: No module named 'pandas'` | Your code reads the candidates with pandas, which `sparkly_lite` does not install. | Run `pip install pandas` with the environment active, or read the file with `pyarrow`, which is installed, as [`block()`](technical-guide.md#block) shows. |
