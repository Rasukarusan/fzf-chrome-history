# fzf-chrome-history

**Fuzzy search and open Chrome history**

![Demo](https://user-images.githubusercontent.com/17779386/56350061-dc7bc180-6204-11e9-84cc-11f0cf919426.gif)

# Requirement

- OS X
- fzf
- GNU Coreutils(gdate)

# Usage

```sh
# Output the latest 10,000 history
$ sh chromeHistory.sh

# grep by PATTERN
$ sh chromeHistory.sh PATTERN

# Date designation
$ sh chromeHistory.sh -d
```

# Option

Select "export" displayed by fzf to stdout to the screen.

![demo_export.gif](https://user-images.githubusercontent.com/17779386/56843356-6a793b80-68da-11e9-84fa-d0d24e63f92f.gif)
