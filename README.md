#Bench G5K

This repository contains some tools to ease the execution of benchmarks on [Grid'5000](https://wwww.grid5000.fr).

## Content

- `bench.sh` script to run benchmarks on a single instance
- `benchd.sh` script to run benchmarks on a cluster
- `env.sh` state the environment (where the btrplace schedulers are available)

## Usage

```
$ oarsub -p "cluster='grisou'" -l nodes=20,walltime=1 -I
$ ./benchd.sh
```

