"""Import only help responses from a pinned, read-only console capture.

Never ship the raw console stream: it can contain unrelated server/private logs.
Only known commands with a Syntax/USAGE header are accepted. Missing help stays
missing; C++ argument signatures remain authoritative for generated forms.
"""
import argparse
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def extract(capture, catalog):
    assert capture['revision'] == catalog['revision'], 'Help and catalog revisions differ'
    names = {e['name'] for e in catalog['entries']}
    result = {}
    for batch in capture['batches']:
        requested = [s.removeprefix('help ') for s in batch['commands']]
        name = requested[0]
        lines = []
        def save():
            text = '\n'.join(lines).strip()
            if name in names and re.match(r'^(### USAGE:|Syntax:)', text):
                # Subcommand lists are already represented by the catalog.
                text = text.split('Possible subcommands:')[0].strip()
                assert len(text) < 12000 and not re.search(r'\x1b|\x00', text)
                result[name] = text
        for line in batch['output'].replace('\r', '').splitlines():
            match = re.match(r'^TC> help (.+)$', line)
            if match:
                save(); name = match[1].strip(); lines = []
            elif line.startswith('TC> '):
                save(); lines = [line[4:]] if re.match(r'^TC> (### USAGE:|Syntax:)', line) else []
            elif lines:
                # Console log prefixes end the response; never import logs.
                if re.match(r'^\d{4}-\d\d-\d\d|^\[|^TC>', line):
                    save(); lines = []
                else:
                    lines.append(line)
        save()
    return result

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', type=Path, required=True)
    args = parser.parse_args()
    catalog = json.loads((ROOT/'docs/commands.json').read_text())
    help_text = extract(json.loads(args.capture.read_text()), catalog)
    output = ['-- Pinned Forever server help; TrinityCore contributors, GPL-2.0-or-later.',
              '-- Imported by tools/generate_command_help.py; no raw console logs.',
              'GMGenie.CommandHelpRevision = '+json.dumps(catalog['revision'])+';',
              'GMGenie.CommandHelp = {']
    for name, text in sorted(help_text.items()):
        output.append('    ['+json.dumps(name)+'] = '+json.dumps(text)+',')
    output.append('};\n')
    (ROOT/'CommandHelp.lua').write_text('\n'.join(output), encoding='utf-8')
    print(f'Imported {len(help_text)} pinned help responses')
