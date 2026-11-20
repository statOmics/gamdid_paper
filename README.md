# gamdid paper

Code and manuscript to reproduce the results and figures of the gamdid paper.

## Requirements

The analyses use the development versions of gamdid and msqrob2, which are
not available from the Bioconductor release. Install them from GitHub:

```r
remotes::install_github("statOmics/msqrob2", ref = "adfd6ed") # msqrob2 1.21.2
remotes::install_github("statOmics/gamdid@v0.99.0")
```

The other R packages that are needed are loaded in `R/packages.R`. Compiling
the manuscript requires `pdflatex` and `biber`.

## Reproducing the paper

Everything is driven by the `Makefile`, run from the repository root:

| Command             | What it does                                                                  |
| ------------------- | ----------------------------------------------------------------------------- |
| `make data`         | Downloads and preprocesses the datasets into `data/` (`make_data.R`)          |
| `make simulations`  | Runs the simulation studies into `simulation_results/` (`make_simulations.R`) |
| `make caseStudy`    | Runs the case study into `caseStudy_results/` (`make_caseStudy.R`)            |
| `make figures`      | Generates all figures and copies them to `manuscript/figs/` (`manuscript/figs/make_figures.R`) |
| `make pdfs`         | Compiles the manuscript and supplementary PDFs from the existing figures (no R is run) |
| `make manuscript`   | `make figures` followed by `make pdfs`                                        |
| `make all`          | `make data`, `make simulations`, `make caseStudy` and `make manuscript`, in order |
| `make clean`        | Removes the LaTeX build artefacts in `manuscript/`                            |

The steps depend on each other: the figures need the simulation and case
study results, which in turn need the data. Each R step writes its log, ending
with the `sessionInfo()`, to the corresponding `make_*.Rout` file.

`make pdfs` builds four PDFs in `manuscript/` from `manuscript/main.tex`:

- `gamdid_manuscript.pdf`
- `gamdid_supplemental_figures.pdf`
- `gamdid_supplemental_tables.pdf`
- `gamdid_supplemental_methods.pdf`

They reference each other's figure, table and section numbers, so they are
always compiled together. The `biber` in `~/bin` is used when present (it must
match the installed biblatex version); override it with e.g.
`make pdfs BIBER=biber`.

## Layout

```
R/                   shared helpers (packages.R, utils.R)
make_*.R             one script per pipeline step
data/                datasets (generated, not tracked)
simulation_results/  simulation output (generated, not tracked)
caseStudy_results/   case study output (generated, not tracked)
figures/scripts/     one script per figure
figures/output/      figures as pdf and jpg
manuscript/          LaTeX sources (main.tex, sections/, bibliography/);
                     the jpg figures it includes are copied to manuscript/figs/
```

Only `manuscript/main.tex` is built. `main_lapreprint.tex`, `main_methods2.tex`,
`sections/methods2.tex`, `sections/methods_old.tex` and
`sections/supplementary.tex` are earlier versions kept for reference.
