"""Print read-only help requests for the bundled catalog. Never executes commands."""
import argparse
import json
from pathlib import Path

def plan(catalog, console=False):
    return [('help ' if console else '.help ')+entry['name'] for entry in catalog['entries'] if not console or entry['console']]

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--console',action='store_true',help='Only include Console::Yes registrations and omit the leading dot')
    args=parser.parse_args()
    catalog=json.loads((Path(__file__).resolve().parents[1]/'docs/commands.json').read_text())
    print('\n'.join(plan(catalog,args.console)))
