var pinfo = {};
pinfo.name = 'Big';
pinfo.licence = 'Proprietary';
pinfo.conflicts = 'No';
pinfo.licences = ['Proprietary (author, 20 files)', 'Apache-2.0 (10 files)', 'BSD (3 files)','MIT (1 file)'];
pinfo.complete = '95%';
pinfo.files = 34;
pinfo.loc = 6700;
var phtml = `
== Project: Big ==
- License from author: Proprietary
- License conflicts found: No
- Licenses found:
	- Proprietary (author, 20 files) 
	- Apache-2.0 (10 files)
	- BSD (3 files)
	- MIT (1 file)
	
- Completeness: 95%
- Files: 34
- LOC: 6700
`;