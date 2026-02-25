\# PC – Owner Manual (Chris’s Windows Machine)



\_Last updated: (update this line when we change things)\_



\## What “PC” means to Mason



When Mason talks about the \*\*pc\*\* area, he means:



\- Your Windows computer as a whole (processes, disk, RAM, temp files, etc.).

\- Things he can \*\*measure\*\*, \*\*log\*\*, and \*\*gently clean or tune\*\* – under risk rules.



The PC is one of Mason’s main areas in his autonomy policy:



\- Area: `pc`

\- Domains (from Mason\_AutonomyPolicy.json):

&nbsp; - `stability`

&nbsp; - `hygiene`

&nbsp; - `performance`

&nbsp; - `security`

&nbsp; - `observability`



Each domain has:

\- A current level (0–3),

\- A target level,

\- Notes about what Mason is allowed to do there.



Mason has to \*\*earn higher levels\*\* by behaving safely.



---



\## Where PC-related scripts live



PC-related tools live in:



\- `C:\\Users\\Chris\\Desktop\\Mason2\\tools`



Examples of scripts that affect or inspect the PC:



\- `Mason\_DiskGuard.ps1`  

&nbsp; Protects disk free space and enforces minimum free space rules.



\- `Mason\_Disk\_Trend\_Watch.ps1`  

&nbsp; Watches how your disk usage changes over time.



\- `Mason\_Forensics\_Inventory.ps1`  

&nbsp; Lists Mason-related and log-related files he may want to clean later.



\- `Mason\_Forensics\_Cleanup.ps1`  

&nbsp; Cleans up old Mason logs / forensic artifacts inside his own folders (not random system files).



\- `Mason\_Health\_Aggregator.ps1`  

&nbsp; Pulls together various health info into a summary.



\_(More may be added over time; this list is just examples.)\_



---



\## How to run PC-related scripts by hand



1\. Open \*\*Windows PowerShell\*\*.

2\. Go to Mason tools:



&nbsp;  ```powershell

&nbsp;  cd "C:\\Users\\Chris\\Desktop\\Mason2\\tools"



