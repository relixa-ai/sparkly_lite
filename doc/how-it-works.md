## How `sparkly_lite` works

This page explains the ideas behind a blocking run. Read it after the [tutorial](tutorial.md) and before the [technical guide](technical-guide.md), which describes the command and the functions one by one. You can skip the first section below if you have worked on entity matching before.

### The blocking step

Call the two input tables table A and table B. The goal is to find pairs of records, one from each table, that refer to the same real-world entity. Such a pair is a *match*. Comparing every row of table A with every row of table B is not feasible for large tables, since two tables of a million rows each form a trillion pairs. Matching is therefore done in two steps.

*Blocking* uses a fast heuristic to select the pairs that could plausibly be matches. Its output is the *candidate set*. `sparkly_lite` performs this step.

*Matching* examines each pair in the candidate set more carefully and decides match or non-match. A matcher, such as Iris, performs this step.

A blocker is judged by two numbers. Its *recall* is the share of the true matches that are in the candidate set. A match that blocking leaves out cannot be found by any matcher, so recall is the number to protect. Its *reduction* is the share of all possible pairs that it leaves out, which determines how much work remains for the matcher.

### The inputs

Each table has an id column that identifies its records. `sparkly_lite` reads the id from the column `_id`, unless `id_col` (`--id-col` on the command line) names another column. Every row must have an id, no id may appear twice, and each id is a whole number, 0 or more. `sparkly_lite` checks this before any work and stops with an error that names the problem. A table without an id column can be given `id_col='_rid'`, which numbers the rows 0, 1, 2 and so on and uses these numbers as the ids. `sparkly_lite` does not support string ids. The section [Tables keyed by strings](technical-guide.md#tables-keyed-by-strings) of the technical guide describes what to do for a table keyed by strings, such as product codes.

The *blocking columns* are the columns whose text is compared. By default, they are all the columns except the id column. The id column is `_id`, or the column that `id_col` (`--id-col`) names. Columns named `id`, `_id` or `_rid` are left out too, since they usually hold ids. For example, for a table with the columns `pid`, `title` and `price`, given with `--id-col pid`, the blocking columns are `title` and `price`. `columns` (`--columns`) names the blocking columns instead. For each record, `sparkly_lite` converts the value of each blocking column to text, treats a missing value as empty, and joins the values with a space into one text.

The tables can be Parquet, CSV, TSV, JSON or JSON Lines files, pandas or Polars DataFrames, or pyarrow Tables. The section [File formats](technical-guide.md#file-formats) of the technical guide describes them.

### Tokens

Before scoring, `sparkly_lite` splits the text of each record into *tokens*. The tokenizer is selected with `tokenizer` (`--tokenizer`), and is `word` by default.

| Tokenizer | Tokens | Example |
|---|---|---|
| `word` | Each sequence of consecutive letters and digits | `Data-Mining, 2nd ed.` gives `data`, `mining`, `2nd`, `ed` |
| `trigram` | Each overlapping 3-character sequence within a sequence of consecutive letters and digits | `mining` gives `min`, `ini`, `nin`, `ing` |
| `hybrid` | The tokens of `word` and of `trigram` together | `mining` gives `mining`, `min`, `ini`, `nin`, `ing` |

All three tokenizers convert upper-case letters to lower case. A letter here is one of the letters A to Z. For now, any other character, including an accented letter such as é, separates tokens and is not part of any token, so `José` gives the token `jos`.

Trigrams still match when a word is misspelled, abbreviated or run together with the next one. A record has many more trigrams than words, so a run with `trigram` or `hybrid` takes longer. Part 6 of the tutorial compares `word` and `trigram` on the same data.

### The score

`sparkly_lite` scores a pair with the BM25 variation of TF/IDF, which is the variation Sparkly uses. By default, each record from table B is compared with records from table A. Each token in the record from table B that also occurs in the record from table A adds to the score of the pair. The amount it adds is larger in three cases:

- when the token is rare among the records of the run, which is the *IDF* part, so that a shared surname counts for more than a common shared token `jack`.
- when the token occurs more often in the record from table A, which is the *TF* part, with each repeat adding less than the one before
- when the record from table A is shorter than average, measured by the number of tokens in the columns being compared.

Two parameters set these effects. `bm25_k1` (`--k1`), 1.2 by default, sets how fast repeats stop adding. `bm25_b` (`--b-param`), 0.75 by default, sets how much the length of the record from table A counts, from 0, not at all, to 1, in full.

The rarity of each token and the average length of a record are computed from the records of the run, from both tables in a run on two tables and from the one table in a deduplication. The same pair can therefore score differently in a run on other tables or on a sample of them.

### The top K and the direction

For each record in table B, `sparkly_lite` selects up to K records from table A with the highest scores. Each candidate pair contains the record from table B and one selected record from table A. K is 20 by default and at most 128. A run on two tables therefore returns at most (number of rows in table B) × K pairs, such as 2,294 × 20 = 45,880 on the papers of the tutorial. Two records must share at least one token to form a candidate pair. If a record from table B shares tokens with fewer than K records from table A, it receives fewer than K candidates.

The *direction* says which table's records receive the K candidates. The default, `b2a`, finds candidates in table A for each record from table B. `a2b` (`--direction a2b`) finds candidates in table B for each record from table A, and returns at most (number of rows in table A) × K pairs. In both directions, the candidate set holds the id of the record from table A in `id1` and the id of the record from table B in `id2`.

K sets the balance between recall and reduction. A smaller K gives fewer pairs and less work for the matcher, but a true match ranked below K is lost. A larger K keeps more of the true matches and gives more pairs. On the papers of the tutorial, K = 20 keeps all 2,224 known matches and K = 5 keeps 2,221 of them (Part 4).

### Deduplication

To find the duplicates within one table, the table is matched against itself. This is *deduplication*. It is selected with `--dedup`, and from Python with `dedup=True` or by giving only table A. Each record receives the K records of the same table with the highest scores, and three things differ from a run on two tables:

1. The pairs of a record with itself are removed.
2. A pair that is found from both of its records, as (x, y) and as (y, x), is kept once, with the higher of its two scores. Each pair is written with the smaller id as `id1`.
3. For a table containing **n records**, there are n × (n − 1) / 2 distinct pairs. The reduction is measured against this number, rather than n × n.

The candidate set is therefore smaller than n × K. [Part 7 of the tutorial](tutorial.md#part-7-finding-the-duplicates-in-a-table-of-1000000-records) shows deduplication on a table of 1,000,000 songs with known duplicate pairs.

Giving the same table as both table A and table B is a run on two tables, not a deduplication. It keeps the pairs of a record with itself and both orders of each pair, so a matcher would see each pair twice. Use `--dedup` instead.

### Recall, reduction and the gold set

A *gold set* is a set of pairs known to be matches, each with the id of a record from table A and the id of a record from table B. Given a gold set (`gold`, `--gold`), `sparkly_lite` counts how many of its pairs are in the candidate set and reports the following:

- `|GT|`, the number of pairs in the gold set
- `Found/GT`, the number of them in the candidate set, out of `|GT|`
- `Recall`, which is `Found/GT` as a percentage

In a deduplication, a gold pair counts as found in either order. A gold pair whose ids are not in the tables counts in `|GT|` but cannot be found. `sparkly_lite` reads the two id columns of the gold set by name, as `id1` and `id2`, `a_id` and `b_id`, `ltable_id` and `rtable_id`, `left_id` and `right_id`, or `lid` and `rid`. Otherwise it uses the first two columns: the first contains record IDs from table A, and the second contains record IDs from table B.

`Reduction` needs no gold set. It is 1 − candidates / ((number of rows in table A) × (number of rows in table B)), the share of all possible pairs between table A and table B that the candidate set leaves out, and in a deduplication 1 − candidates / (n × (n − 1) / 2).

Recall is measured against the gold set only. A gold set that lists only some of the true matches measures the recall of those, and says nothing about the others.

`evaluate` measures the same recall for a candidate set that was saved earlier, without blocking again. Given `dedup=True`, it counts a gold pair as found in either order, as a deduplication does.

### The candidate set

To save the candidate set to a file, pass the file name with `--out` on the command line, as in `--out candidates.parquet`, or with the argument `out` of `block` in Python, as in `out="candidates.parquet"`. The file holds one row per pair, with the columns `id1`, `id2` and `blocking_score`, as Parquet by default, or as CSV, TSV or JSON Lines, selected by the extension of the file. The section [Output files](technical-guide.md#output-files) of the technical guide describes the formats.

### The row limit

`sparkly_lite` handles up to 3,000,000 rows in each table. A run with more rows in either table is refused before any work, with a `LimitError`. The joined text of the blocking columns of one table must also be under 4 GB. For larger tables, contact [our team](mailto:hello@relixa.ai).

### What determines the result

When recall is lower than expected, the possible causes are listed below, in the order in which to check them.

1. *The gold set.* Check that its ids are the ids of the tables, with table A's in the first column, and that it lists the true matches completely.
2. *K.* A larger K keeps more of the true matches. Measure recall at a few values of K, as Part 4 of the tutorial does, before settling on one.
3. *The blocking columns.* A column that identifies an entity, such as a name or a title, helps. A column that is mostly empty, or that holds the same value in most records, adds noise. Part 5 of the tutorial blocks on chosen columns.
4. *The tokenizer.* On text with misspellings, abbreviations or words run together, `trigram` or `hybrid` can find pairs that `word` misses.
5. *Letters outside A to Z.* They are not part of any token, as described under [Tokens](#tokens). Text written mostly in other letters gives few tokens and weak scores.
