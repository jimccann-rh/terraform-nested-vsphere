#!/usr/bin/python3

import argparse
import json
import pprint


pp = pprint.PrettyPrinter()
parser = argparse.ArgumentParser()

parser.add_argument("-j","--json")
parser.add_argument("-t","--template")
parser.add_argument("-v","--variable")

args = parser.parse_args()

terraform_variables = ""

with open(args.json) as file:
    config = json.load(file)

    for key in config['new_vcsa'].keys():
        for next_key in config['new_vcsa'][key].keys():
            if next_key.find("__") == -1:
                if isinstance(config['new_vcsa'][key][next_key], str):
                    config['new_vcsa'][key][next_key] = "${{{0}_{1}}}".format(key, next_key)
                    terraform_variables += "variable \"{0}_{1}\" {{\ntype = string\n}}\n".format(key, next_key)
                if isinstance(config['new_vcsa'][key][next_key], list):
                    terraform_variables += "variable \"{0}_{1}\" {{\ntype = list\n}}\n".format(key, next_key)
                    config['new_vcsa'][key][next_key] = "${{{0}_{1}}}".format(key, next_key)

with open(args.template, "w") as outfile:
    json.dump(config, outfile)


with open(args.variable, "wt") as outfile:
    outfile.write(terraform_variables)
    outfile.close()
