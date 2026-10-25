## `sparkly_lite` tutorial

Follow Parts 1 to 7 in Terminal to generate candidate pairs, save them to a file, and compare blocking settings on the included data. Part 8 shows how to do the same work in a Python notebook. Complete the parts in order; each builds on the previous ones.

### Before you begin

First, install `sparkly_lite` by following the [installation guide](installation.md). Wait for `Installation complete.` before continuing.

Open Terminal from **Applications → Utilities → Terminal**, or keep using the Terminal window from installation. Go to the downloaded `sparkly_lite` folder, which contains `install.sh` and `data`. If you are opening a new Terminal window, type `cd` followed by a space, drag the `sparkly_lite` folder from Finder into Terminal, and press Return.

Activate the installed Python environment. Run this command in Terminal:

```bash
source .venv/bin/activate
```

This makes the `sparkly-lite` command available in this Terminal window. Your prompt should now start with `(.venv)`.

Run all Terminal commands below in this same window, from the `sparkly_lite` folder. Copy each command block into Terminal and press Return. Blocks labeled **Example output** show what the command prints; you do not need to enter those blocks. If you open a new Terminal window later, return to the folder and activate the environment again.

### The sample data

Three datasets are included with `sparkly_lite`, in the `data` directory. The tutorial uses the first two.

| Dataset | What it is | Size |
|---|---|---|
| `data/dblp_acm` | Two tables of computer-science papers, DBLP (2,616 rows) and ACM (2,294 rows), with a gold set of the 2,224 pairs known to be the same paper. | 380 KB |
| `data/music_1m` | One table of 1,000,000 songs that contains duplicates of its own records, with a gold set of the 146,011 known duplicate pairs. | 50 MB |
| `data/abt_buy` | Two tables of electronics products as two stores list them, Abt (1,081 rows) and Buy (1,092 rows), with a gold set of the 1,097 pairs known to be the same product. The [quick start](https://www.relixa.ai/try-relixa) on the Relixa website uses it. | 244 KB |

The example outputs below were recorded on a Mac with an M5 Pro chip and 48 GB of memory. Run times may vary depending on your machine.

### Part 1: Blocking two tables

Generate candidates for the ACM papers using the DBLP papers as possible matches. Run this command in Terminal:

```bash
sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet
```

**Example output:**

```text
Dataset           dblp_acm
|A|               2,616
|B|               2,294
Blocking Columns  title, authors, venue, year
K                 20
Candidates        45,880
Reduction         99.2355%
Time              77 ms
```

This command reads DBLP as table A and ACM as table B. For each ACM record, it selects up to 20 DBLP records with the highest TF/IDF scores. Check the `Candidates` row in your output: this example produces 45,880 pairs. The command prints a summary; Part 3 shows how to save the pairs.

The table below explains each row of the output.

| Row | What it shows |
|---|---|
| `Dataset` | The name of the directory that holds table A, as a label for the run. |
| `\|A\|` | The number of rows of table A. |
| `\|B\|` | The number of rows of table B. |
| `Blocking Columns` | The columns whose text is compared. By default these are all the columns except the id. Part 5 selects them. |
| `K` | The number of candidates kept for each record of table B. Part 4 changes it. |
| `Candidates` | The number of pairs returned by the blocker, here \|B\| × K = 2,294 × 20 = 45,880. |
| `Reduction` | The share of all possible pairs between table A and table B that the blocker left out. |
| `Time` | The time from reading the tables to having the candidates. Saving them, as in Part 3, is not included. The first run after the installation takes longer, 1.70 seconds on the Mac of this tutorial. |

Table A and table B form 2,616 × 2,294 = 6,001,104 pairs, and the blocker kept 45,880 of them. In the matching step, a matcher examines each of these pairs that blocker kept and predicts match or non-match. Part 2 measures how many of the true matches they contain.

### Part 2: Measuring recall against a gold set

Check how many known matches are included in the candidates. Run the command again in Terminal, adding the included reference file with `--gold`:

```bash
sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet \
    --gold data/dblp_acm/gold.parquet
```

**Example output:**

```text
Dataset           dblp_acm
|A|               2,616
|B|               2,294
|GT|              2,224
Blocking Columns  title, authors, venue, year
K                 20
Candidates        45,880
Reduction         99.2355%
Found/GT          2,224/2,224
Recall            100.00%
Time              77 ms
```

The reference file is a *gold set*: it lists 2,224 pairs known to be the same paper. Adding `--gold` compares the candidates with these known matches. Look for `Found/GT` and `Recall` in your output.

The output has three new rows.

| Row | What it shows |
|---|---|
| `\|GT\|` | The number of pairs in the gold set. GT stands for ground truth. |
| `Found/GT` | The number of gold pairs among the candidates, out of `\|GT\|`. |
| `Recall` | `Found/GT` as a percentage. |

All 2,224 known matches are among the 45,880 candidates, so the recall is 100%. A match that blocking leaves out cannot be found by any matcher, so recall is the number to protect when the settings are chosen in Parts 4 to 6. [How `sparkly_lite` works](how-it-works.md#recall-reduction-and-the-gold-set) describes how the gold set is read.

### Part 3: Saving the candidate pairs

Save the candidate pairs so you can inspect them or pass them to a matcher. Run this command in Terminal, adding `--out candidates.csv`:

```bash
sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet \
    --gold data/dblp_acm/gold.parquet --out candidates.csv
```

The `--out` option writes `candidates.csv` into your current `sparkly_lite` folder. Check that the summary ends with a `Saved` row:

**Example output:**

```text
...
Time              78 ms
Saved             candidates.csv (45,880 rows)
```

Inspect the header and first three pairs. Run this command in the same Terminal window:

```bash
head -4 candidates.csv
```

**Example output:**

```text
id1,id2,blocking_score
2123,0,63.265366
1941,0,21.282175
1552,0,17.441315
```

Each row is one pair, with the id of the record of table A in `id1`, the id of the record of table B in `id2`, and the TF/IDF score in `blocking_score`. A higher score means more similar records. The rows are grouped by the record of table B, so these are the three best candidates of the record from table B whose id is 0.

This file is the output of the blocker, which a matcher reads in the matching step. The extension `.csv` selects CSV. Without an extension, or with `.parquet`, `--out` writes Parquet, which is the format Relixa's matchers read by default. The section [Output files](technical-guide.md#output-files) of the technical guide lists the formats.

### Part 4: Choosing K

Compare the default 20 candidates per record with a smaller set of 5. Run this command in Terminal, setting `--k 5`:

```bash
sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet \
    --gold data/dblp_acm/gold.parquet --k 5
```

**Example output:**

```text
K                 5
Candidates        11,470
Reduction         99.8089%
Found/GT          2,221/2,224
Recall            99.87%
Time              78 ms
```

Compare the `Candidates` and `Recall` rows with Part 2. K is the maximum number of candidates kept for each record from table B. A smaller K gives the matcher fewer pairs to examine, but a true match is lost if the matching record from table A ranks below K for the record from table B.

Going from K = 20 to K = 5 reduces the candidates from 45,880 to 11,470, and 3 of the 2,224 true matches fall outside the top 5. No later step can recover a pair that blocking drops. With K = 1, the command returns 2,294 candidates, with a recall of 99.10%.

The titles of DBLP and ACM are distinctive, so on these tables the best candidate is usually the right one. On tables with more errors, recall falls faster as K decreases. Compare several values now. Run this loop in Terminal to print one summary for each value of K:

```bash
for k in 5 10 20 50; do
  sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet \
    --gold data/dblp_acm/gold.parquet --k "$k" --quiet
done
```

The loop runs blocking four times with K = 5, 10, 20 and 50. Compare the `Candidates` and `Recall` rows to see how many extra pairs are needed to retain more known matches.

If you have a gold set, compare settings and choose the smallest K whose recall is acceptable. Otherwise, start with the default K of 20 and inspect candidates for a sample of records. Try a larger K to see whether it includes additional plausible matches. To measure recall, you’ll need a sample with known matches identified independently of the blocker.

### Part 5: Choosing the blocking columns

Compare only paper titles and authors, leaving out venue and year. Run this command in Terminal, adding `--columns title,authors`:

```bash
sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet \
    --gold data/dblp_acm/gold.parquet --columns title,authors
```

**Example output:**

```text
Blocking Columns  title, authors
K                 20
Candidates        45,670
Reduction         99.2390%
Found/GT          2,224/2,224
Recall            100.00%
Time              75 ms
```

The `--columns` option selects the text columns to compare; separate their names with commas. Without it, these tables use `title`, `authors`, `venue` and `year`. Check that `Blocking Columns` now shows only `title, authors`, then compare `Candidates` and `Recall` with Part 2.

With the columns `title` and `authors`, the recall is still 100%. The candidates are 210 fewer than 2,294 × 20, because two records must share at least one token to form a candidate pair. For 16 records in table B, fewer than 20 records in table A share any words in the `title` or `authors` columns. Those records therefore receive fewer than 20 candidates each.

### Part 6: Choosing the tokenizer

Try comparing 3-character sequences instead of whole words. Run this command in Terminal with `--tokenizer trigram`:

```bash
sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet \
    --gold data/dblp_acm/gold.parquet --tokenizer trigram
```

**Example output:**

```text
K                 20
Candidates        45,880
Reduction         99.2355%
Found/GT          2,224/2,224
Recall            100.00%
Time              124 ms
```

The `trigram` tokenizer splits text into overlapping 3-character sequences within words; for example, `mining` gives `min`, `ini`, `nin` and `ing`. Misspelled words can still share some of these sequences. The default tokenizer, `word`, uses sequences of consecutive letters and digits, and `hybrid` uses both. See [Tokens](how-it-works.md#tokens) for details.

Compare the `Recall` and `Time` rows with Part 2. In the example outputs, the recall is the same, and the trigram run took 124 ms instead of 77 ms, because a record has many more trigrams than words. On these tables `word` already finds every known match, so `trigram` adds time without adding recall. On tables with many misspellings the comparison can come out the other way. We recommend trying both tokenizers on your own data.

### Part 7: Finding the duplicates in a table of 1,000,000 records

Find possible duplicates within a single table using the included dataset of 1,000,000 songs. Run this command in Terminal with one input table and `--dedup` to compare records within that table, and `--gold` to measure recall:

```bash
sparkly-lite block data/music_1m/table_a.parquet --dedup \
    --gold data/music_1m/gold.parquet
```

Comparing records within one table is called *deduplication*. The `--dedup` option compares the songs table with itself. While it runs, Terminal displays a progress line showing the number of rows processed and the estimated time remaining. A run on this dataset can take a few minutes:

**Example output:**

```text
  [sparkly-lite]    412,730/1,000,000 ( 41.3%) | ETA: 1m28s
```

When the command finishes, look for the `Candidates`, `Found/GT` and `Recall` rows in the summary:

**Example output:**

```text
Dataset           music_1m
Mode              dedup (self-join)
|A|               1,000,000
|GT|              146,011
Blocking Columns  title, release, artist_name, duration, year
K                 20
Candidates        12,530,036
Reduction         99.9975%
Found/GT          141,925/146,011
Recall            97.20%
Time              2m 26s
```

Check that the summary shows `Mode` set to `dedup (self-join)` and only one table size, `|A|`. Deduplication removes pairs of a record with itself and keeps each candidate pair once, even if it is found in both orders. See [How deduplication works](how-it-works.md#deduplication) for details.

The table forms 499,999,500,000 distinct pairs. The blocker kept 12,530,036 of them, a reduction of 99.9975%, and these contain 141,925 of the 146,011 known duplicate pairs, a recall of 97.20%. The run took 2 minutes and 26 seconds. Run times may vary depending on your machine. To compare a larger candidate set, rerun the command with `--k 50` added. In that run, the blocker keeps 32,982,546 pairs, with a recall of 99.13%.

### Part 8: The same work from Python

Open the included notebook to repeat the blocking steps in Python, inspect saved pairs, and measure their recall. First install Jupyter by running this command in the same Terminal window, with `(.venv)` still shown in the prompt:

```bash
pip install notebook
```

This installs Jupyter into the `.venv` environment. Wait for the command to finish and the Terminal prompt to return. Then open the notebook by running this command in Terminal, from the same `sparkly_lite` folder:

```bash
jupyter notebook demo.ipynb
```

Jupyter starts in Terminal and opens `demo.ipynb` in your browser. If the browser does not open, copy the address printed by Jupyter into your browser. Keep this Terminal window open while you use the notebook.

In the browser, select the first code cell and press **Shift+Enter** to run it. Wait for its output, then run the remaining cells in order the same way. Read the text above each cell to see what to check in its output. The cell using the million-song dataset can take a few minutes.

The notebook repeats Parts 1, 2, 4, 5 and 7 using `sl.block`, reads saved pairs into Python, and measures recall with `sl.evaluate`. Python code belongs in the notebook's code cells; Terminal commands belong in Terminal.

For reference, the following block shows calls used by the notebook. You do not need to run this block separately:

```python
import pyarrow.parquet as pq
import sparkly_lite as sl

summary = sl.block("data/dblp_acm/table_a.parquet", "data/dblp_acm/table_b.parquet",
                   gold="data/dblp_acm/gold.parquet", k=10)

sl.block("data/dblp_acm/table_a.parquet", "data/dblp_acm/table_b.parquet",
         columns=["title", "authors"], k=10, out="candidates.parquet")
pairs = pq.read_table("candidates.parquet")
report = sl.evaluate("candidates.parquet", "data/dblp_acm/gold.parquet")

summary = sl.block("data/music_1m/table_a.parquet",
                   gold="data/music_1m/gold.parquet", dedup=True, k=20)
```

The table below explains each call.

| Call | Returns | What it does |
| --- | --- | --- |
| `sl.block(table_a, table_b, gold=..., k=10)` | a `dict` | Performs the same run as `sparkly-lite block` and prints the same summary. The numbers of the summary are in the `dict`, such as `n_candidates`, `reduction`, `recall` and `seconds`. |
| `sl.block(..., out="candidates.parquet")` | a `dict` | Saves the candidate pairs to a file, as `--out` does in Part 3. |
| `pq.read_table("candidates.parquet")` | a pyarrow Table | Reads the saved pairs into Python, with the columns `id1`, `id2` and `blocking_score`. `pq` is `pyarrow.parquet`, which is installed with `sparkly_lite`. |
| `sl.evaluate("candidates.parquet", gold)` | a `dict` | Measures the recall of the saved pairs against the gold set, without blocking again. |
| `sl.block(table_a, gold=..., dedup=True, k=20)` | a `dict` | Finds the duplicates in one table, as `--dedup` does in Part 7. |

The notebook also compares several values of K. Compare the candidate counts and recall printed by that cell, as you did in Part 4. When you have finished, save the notebook in the browser. To stop Jupyter, return to Terminal, press Ctrl-C, and follow any shutdown prompt. The [technical guide](technical-guide.md) describes `block` and `evaluate`, and the Python name of each command-line option.

### Summary

This completes the tutorial. In the eight parts you have blocked two tables, measured recall against a gold set, saved the candidate pairs, changed K, the blocking columns and the tokenizer, found possible duplicates within a table of a million songs, and performed the same work from Python.

## Going further

### A workflow of your own

For your own data, use [Parts 1 and 3](#part-1-blocking-two-tables) to block two tables and save the candidates, or [Part 7](#part-7-finding-the-duplicates-in-a-table-of-1000000-records) to find duplicates within one table. Use [Part 4](#part-4-choosing-k) to compare settings against known matches. When recall is lower than expected, the usual causes are the gold set, K, the blocking columns and the tokenizer, which [How `sparkly_lite` works](how-it-works.md#what-determines-the-result) discusses in that order.

### What your files need

Each table needs an id column of unique values, the columns to block on, and, to measure recall, a gold set. The section [What your files need](technical-guide.md#what-your-files-need) of the technical guide describes each, and the section [File formats](technical-guide.md#file-formats) the formats `sparkly_lite` reads.

---

- [Technical guide](technical-guide.md). The `sparkly-lite` command and every public function, with its arguments, steps and return value. It also covers the input and output file formats.
- [How `sparkly_lite` works](how-it-works.md). The concepts behind each step.
- [Troubleshooting](troubleshooting.md). The error messages, what they mean, and what to do.
