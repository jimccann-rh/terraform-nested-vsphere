#!/usr/bin/python3

import argparse
import json
import pprint


pp = pprint.PrettyPrinter()
parser = argparse.ArgumentParser()

parser.add_argument("-j","--json")
parser.add_argument("-t","--template")

args = parser.parse_args()

with open(args.json) as file:
    config = json.load(file)

    for key in config['new_vcsa'].keys():
        for next_key in config['new_vcsa'][key].keys():
            #pp.pprint(next_key.find("__"))
            if next_key.find("__") == -1:
                if isinstance(config['new_vcsa'][key][next_key], str):
                    config['new_vcsa'][key][next_key] = "${{{0}_{1}}}".format(key, next_key)
                if isinstance(config['new_vcsa'][key][next_key], list):
                    #pp.pprint(type(config['new_vcsa'][key][next_key]))
                    config['new_vcsa'][key][next_key] = "${{{0}_{1}}}".format(key, next_key)

with open(args.template, "w") as outfile:
    json.dump(config, outfile)

