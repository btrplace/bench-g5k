#Bench G5K

This repository contains some tools to ease the execution of benchmarks on [Grid'5000](https://wwww.grid5000.fr).

## Content

- `bench.sh` script to run benchmarks on a single instance
- `benchd.sh` script to run benchmarks on a cluster
- `env.sh` state the environment (where the btrplace schedulers are available)

## Requirements

- maven
- git and an access to github.com/btrplace/*
- java 8
- R to plot

## Usage

1. Book some nodes, _e.g._ `oarsub -p "cluster='grisou'" -l nodes=20,walltime=1 -I`
2. Run the benchmark using `benchd.sh`, _e.g._

````
$ ./benchd.sh -h                                                        
Usage: ./benchd.sh [-c commit] [-l label] [-- bench_params]
Run the benchmark and publish the results in ~/public/label

  -c commit: use the given commit identifier for the scheduler. (default: master)
  -l label: identify the benchmark with the given label. (default is 'commit')
  bench_params: will be passed to bench.sh. (default: '-t 60 -r -v 1')
````





