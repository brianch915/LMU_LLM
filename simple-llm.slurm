#!/bin/bash
#SBATCH --job-name=simple-llm
#SBATCH --output=simple-llm_%j.out
#SBATCH --error=simple-llm_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --partition=lrz-cpu

source ~/LMU_LLM/venv/bin/activate

cd ~/LMU_LLM

python simple-llm.py