"""Generate a fail-closed command catalog from a pinned Forever source checkout.

No server connection or credentials are required. C++ argument definitions are
preserved verbatim; legacy char* handlers deliberately do not invent syntax.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

TOKEN = re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|//[^\n]*|/\*[\s\S]*?\*/')

def uncomment(text):
    return TOKEN.sub(lambda m: re.sub(r'[^\n]', ' ', m[0]) if m[0].startswith(('/',)) else m[0], text)

def balanced(text, start, opening='{', closing='}'):
    depth = 0
    strings = {m.start(): m.end() for m in TOKEN.finditer(text) if m[0].startswith(('"', "'"))}
    i = start
    while i < len(text):
        if i in strings:
            i = strings[i]; continue
        if text[i] == opening: depth += 1
        if text[i] == closing:
            depth -= 1
            if depth == 0: return i
        i += 1
    raise ValueError('Unbalanced C++ initializer/signature')

def split_args(text):
    parts, start, depth, i = [], 0, 0, 0
    strings = {m.start(): m.end() for m in TOKEN.finditer(text) if m[0].startswith(('"', "'"))}
    while i < len(text):
        if i in strings: i = strings[i]; continue
        char = text[i]
        if char in '<({[': depth += 1
        elif char in '>)}]': depth -= 1
        elif char == ',' and depth == 0: parts.append(text[start:i].strip()); start = i+1
        i += 1
    if text[start:].strip(): parts.append(text[start:].strip())
    return parts

def parse_source(text, filename, permissions):
    clean = uncomment(text)
    blocks = []
    for match in re.finditer(r'GetCommands\(\)\s+const\s*(?:override\s*)?\{', clean):
        end = balanced(clean, match.end()-1)
        blocks.append((match.end(), end))
    records, registrations = [], 0
    for begin, end in blocks:
        tables = {}
        for match in re.finditer(r'\bChatCommandTable\s+(\w+)\s*=\s*\{', clean[begin:end]):
            start = begin+match.end()-1
            stop = balanced(clean, start)
            entries, i = [], start+1
            while i < stop:
                if clean[i].isspace() or clean[i] == ',': i += 1; continue
                if clean[i] != '{': raise ValueError(f'{filename}: unparsed initializer {clean[i:i+60]}')
                finish = balanced(clean, i)
                entries.append((split_args(clean[i+1:finish]), clean.count('\n',0,i)+1))
                i = finish+1
            tables[match[1]] = entries
        root = re.search(r'\breturn\s+(\w+)\s*;', clean[begin:end])
        if not root or root[1] not in tables: raise ValueError(f'{filename}: missing root table')
        visited = set()
        def walk(table, prefix):
            nonlocal registrations
            if table in visited: raise ValueError(f'{filename}: repeated/cyclic table {table}')
            visited.add(table)
            for args, line in tables[table]:
                registrations += 1
                name = json.loads(args[0])
                full = ' '.join(p for p in (prefix,name) if p)
                if len(args) == 2:
                    walk(args[1], full); continue
                old = args[1].startswith('rbac::')
                if old and len(args) == 6:
                    assert args[3] == 'nullptr', (filename,args)
                    walk(args[5], full); continue
                if old:
                    assert len(args) == 5 and args[2] in ('true','false'), (filename,args)
                    permission, console, handler = args[1], args[2]=='true', args[3].lstrip('&')
                else:
                    assert len(args) in (4,5), (filename,args)
                    handler, permission, console = args[1], args[-2], args[-1]=='Console::Yes'
                    assert args[-1] in ('Console::Yes','Console::No'), (filename,args)
                enum = permission.removeprefix('rbac::')
                if enum not in permissions: raise ValueError(f'{filename}: unknown permission {enum}')
                base = handler.split('<')[0]
                signature = re.search(r'\bbool\s+'+re.escape(base)+r'\s*\(', clean)
                if not signature: raise ValueError(f'{filename}: missing handler {handler}')
                a = signature.end()-1; b = balanced(clean,a,'(',')')
                params = split_args(clean[a+1:b])
                assert 'ChatHandler' in params[0], (filename,params)
                arguments = ', '.join(re.sub(r'\s+', ' ', p) for p in params[1:])
                legacy = bool(re.search(r'char\s+const\s*\*|const\s+char\s*\*',arguments))
                outline=[]
                for index,param in enumerate(params[1:],1):
                    argname=re.search(r'\b(\w+)\s*(?:=.*)?$',param)
                    argname=argname[1] if argname else f'value{index}'
                    outline.append('['+argname+']' if param.strip().startswith('Optional<') else '<'+argname+('...' if 'std::vector<' in param else '')+'>')
                usage='.'+full+(' <arguments: see Server help>' if legacy else (' '+ ' '.join(outline) if outline else ''))
                records.append(dict(name=full, arguments=arguments, usage=usage, legacy=legacy,
                    permission=enum, permissionId=permissions[enum], console=console,
                    handler=handler, source=filename, line=line))
        walk(root[1], '')
        if set(tables) != visited: raise ValueError(f'{filename}: unreachable tables {set(tables)-visited}')
    return records, registrations

def generate(source, output, revision=None):
    metadata_path = source/'metadata.json'
    if metadata_path.exists():
        metadata=json.loads(metadata_path.read_text())
        revision=revision or metadata['revision']; files=metadata['command_files']
    else:
        revision=revision or subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip()
        files=[p for p in subprocess.check_output(['git','-C',str(source),'grep','-l','GetCommands() const override','--','src'],text=True).splitlines()]
    assert re.fullmatch('[0-9a-f]{40}',revision), 'Use a full commit SHA'
    permissions=dict((name,int(value)) for name,value in re.findall(r'\b(RBAC_PERM_\w+)\s*=\s*(\d+)',(source/'src/server/game/Accounts/RBAC.h').read_text(encoding='utf-8')))
    entries, total, hashes = [], 0, {}
    for file in sorted(files):
        data=(source/file).read_bytes(); hashes[file]=hashlib.sha256(data).hexdigest()
        parsed,count=parse_source(data.decode('utf-8-sig'),file,permissions)
        if not count: raise ValueError(f'No command tables parsed: {file}')
        entries.extend(parsed); total+=count
    entries.sort(key=lambda e:e['name'])
    names=[e['name'] for e in entries]
    assert len(names)==len(set(names)), 'Duplicate command paths'
    catalog={'revision':revision,'forkRevision':'85d3c25180a89f889294d54d855efccae0945f20','registrations':total,'files':hashes,'entries':entries}
    (output/'docs').mkdir(parents=True,exist_ok=True)
    (output/'docs/commands.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
    quote=lambda s:json.dumps(s,ensure_ascii=True)
    lines=['-- Generated by tools/generate_commands.py. Do not edit.', '-- Command registrations: TrinityCore contributors / advocaite Forever (GPL-2.0-or-later).',
           'GMGenie.CommandData = { revision = '+quote(revision)+', forkRevision = '+quote(catalog['forkRevision'])+', entries = {']
    for e in entries:
        fields=[f'{k} = '+(quote(v) if isinstance(v,str) else str(v).lower()) for k,v in e.items()]
        lines.append('    { '+', '.join(fields)+' },')
    lines.append('} };\n')
    (output/'CommandData.lua').write_text('\n'.join(lines),encoding='utf-8')
    print(json.dumps({'commands':len(entries),'registrations':total,'source_files':len(files),'revision':revision}))
    return catalog

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-root',type=Path,required=True)
    parser.add_argument('--output',type=Path,default=Path(__file__).resolve().parents[1])
    parser.add_argument('--revision')
    args=parser.parse_args(); generate(args.source_root,args.output,args.revision)
