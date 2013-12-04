haiku-finder-five
=================

A small script to find<br/>
[haiku](https://en.wikipedia.org/wiki/Haiku) hiding in your text<br/>
your miles may vary.

## Usage

1. Clone this repo: `git clone https://github.com/mildmojo/haiku-finder-five.git && cd haiku-finder-five`
2. Install dependencies: `gem install scalpel sqlite3`
3. Grab a copy of the [GNU Collaborative International Dictionary of English](http://ftp.gnu.org/gnu/gcide/).
4. Extract the `CIDE.*` files alongside the `load_gcide.rb` script in your copy
of this repo: `tar zxvf gcide-0.51.tar.gz "CIDE.*"`
5. Create the word/syllable lookup database: `ruby load_gcide.rb`
6. Run the haiku finder across your text file or PDF:

```
$ ruby find_haiku.rb my_resume.pdf
PERFECT
In my spare time I
collect vintage bottle caps
from antique bottles.
```

Haiku marked "PERFECT" are single sentences that follow the 5/7/5 structure.
The finder only processes whole sentences at this time. In the future, it may be
expanded to combine multiple sentences to form haiku.

Other reported haiku are sentences truncated after the 5/7/5 pattern is
satisfied.

## Known Issues

The GCIDE database doesn't typically include plurals, conjugations, or noun
suffixes. The script may retry failed lookups with na&iuml;ve strategies for
finding root words.

The GCIDE database doesn't always include accurate pronunciation guides, which
this software uses to calculate syllable counts. It's a good idea to
double-check detected haiku for proper syllable counts.

LICENSE
=======

Beware of license<br/>
Affero GPL, man<br/>
relicense when cleaned
