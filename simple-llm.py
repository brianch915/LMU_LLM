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
)

# create the prompt TODO
prompt = f"""generate the answer of 1 + 1 please"""

# add the prompt to the dialogue
messages = [
    {"role": "user", "content": prompt},
]


terminators = [
    generator.tokenizer.eos_token_id,
    generator.tokenizer.convert_tokens_to_ids("<|eot_id|>")
]
# run the model with the messages
outputs = generator(
        messages,
        max_new_tokens=256, # TODO
        eos_token_id=terminators,
        do_sample=False, # TODO
        temperature=None, # TODO
        top_p=None, # TODO
)
# read the response
response=outputs[0]["generated_text"][-1]['content']
print("Input: ", prompt)
print("Output: ", response)
print("")