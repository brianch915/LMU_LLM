#!/bin/bash
#SBATCH --job-name=simple-llm
#SBATCH --output=simple-llm_%j.out
#SBATCH --error=simple-llm_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=02:00:00
#SBATCH --mem=64G
#SBATCH --partition=test-v100x2
#SBATCH --gres=gpu:1
#SBATCH --qos=gpu

source ~/LMU_LLM/venv/bin/activate

cd ~/LMU_LLM

python simple-llm.py
