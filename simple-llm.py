import pandas as pd
import torch
from tqdm import tqdm
import accelerate
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline

# local dir to the models (tell us what other models you need and we will update this for you)
local_dir = "/dss/dssmcmlfs01/pn25ju/pn25ju-dss-0000/models/Llama-3.1-8B"
#local_dir = "/dss/dssmcmlfs01/pn25ju/pn25ju-dss-0000/models/gemma-2-9b-it"
#local_dir = "/dss/dssmcmlfs01/pn25ju/pn25ju-dss-0000/models/Mistral-7B-Instruct-v0.3"
#local_dir = "/dss/dssmcmlfs01/pn25ju/pn25ju-dss-0000/models/Qwen2.5-7B-Instruct"
# .../Baichuan2-7B-Chat
# .../glm-4-9b-chat-hf
# .../models--deepseek-ai--DeepSeek-V3
# ...

# load the models from the local_dir
model = AutoModelForCausalLM.from_pretrained(local_dir, torch_dtype="auto", device_map="auto")
tokenizer = AutoTokenizer.from_pretrained(local_dir)

# Create the pipeline
generator = pipeline(
    "text-generation",
    model=model,
    tokenizer=tokenizer,
    device=-1, # force CPU
)

# create the prompt TODO
prompt = f"""generate the answer of 1 + 1 please"""

# run the model with the messages
outputs = generator(
        prompt,
        max_new_tokens=256, # TODO
        do_sample=False, # TODO
)

# read the response
response=outputs[0]["generated_text"]
print("Input: ", prompt)
print("Output: ", response)
