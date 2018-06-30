# Savemultifigs+

This is the updated version based on [Save Multiple Figures in a click](https://ww2.mathworks.cn/matlabcentral/fileexchange/35082-save-multiple-figures-in-a-click).

Some bugs are fixed, and some new features are added.



---

- To do list:

	- [] Function: remove the title of figures when saving. Or change the title's content (trivial)?
	- [] API: run in command line mode. commandline params support, config file support.

- bugs:

- If the figure is plotted using `plotyy`, only one axis is saved. Another axis is missing. But if you use "File>Save As", you can get figure with two axes.
