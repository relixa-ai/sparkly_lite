## `sparkly_lite`: TF/IDF Blocking for Entity Matching

`sparkly_lite` is a tool for the blocking step of entity matching. Entity matching finds tuples from two tables, called table A and table B, that match, that is, refer to the same real-world entity. It typically proceeds in two steps. *The blocking step* uses heuristics to quickly identify a relatively small set of tuple pairs that can be matches. *The matching step* examines each surviving pair more carefully and predicts match or non-match. (See [this page](https://anhaidgroup.github.io/magellan/about) for details.)

* `sparkly_lite` runs on a single Mac with Apple silicon, and installs into one directory.
* It blocks tables of up to 3,000,000 rows each.
* It uses the TF/IDF similarity measure to perform blocking, in the BM25 variation. For each record of one table, it finds the K records of the other table with the highest score.
* It runs from the command line or from Python, and writes the candidate pairs as Parquet, CSV, TSV or JSON Lines, with the columns `id1`, `id2` and `blocking_score`.

`sparkly_lite` is a simplified version of [Sparkly](https://github.com/anhaidgroup/sparkly). For the matching step, see [Iris](https://github.com/relixa-ai/iris).

### How `sparkly_lite` Works

Call the two input tables table A and table B. `sparkly_lite` reads the id of each record, from the column `_id` by default, and the columns to block on, which by default are all the other columns. For each record it joins the values of these columns into one text, and splits the text into *tokens*: words by default, overlapping 3-character sequences (*trigrams*), or both.

For each record in table B, `sparkly_lite` finds up to K records in table A with the highest TF/IDF scores, where K is a parameter specified by the user and is 20 by default. It pairs each selected record from table A with the record from table B and returns these pairs, each with its score, as the *candidate set*, which is the output of the blocker. A table can also be matched against itself to find its duplicates.

Implementation-wise, `sparkly_lite` is a Python package, installed from a compiled wheel, with a command, `sparkly-lite block`, and a Python function of the same name, `block`, that performs the same run. A second function, `evaluate`, measures the recall of a candidate set saved earlier. See [this page](doc/how-it-works.md) for more details.

### Installation

A `sparkly_lite` run needs a Mac with Apple silicon, such as an M1 or later, running macOS 11 or later, and Python 3.9 or later. See instructions to install `sparkly_lite` on [a Mac with Apple silicon](doc/installation.md).

### How to Use

Start with the [tutorial](doc/tutorial.md) for command-line and Python examples. See the [technical guide](doc/technical-guide.md) for the full reference and [troubleshooting](doc/troubleshooting.md) for help with errors.

#### For questions / comments, contact [our team](mailto:hello@relixa.ai).
