var blocklyArea = document.getElementById('blocklyArea');
var blocklyDiv = document.getElementById('blocklyDiv');
var workspace = Blockly.inject(
	 blocklyDiv,
	 {
		  toolbox: document.getElementById('toolbox')
	 }
);
var onresize = function(e) {
	 // Compute the absolute coordinates and dimensions of blocklyArea.
	 var element = blocklyArea;
	 var x = 0;
	 var y = 0;
	 do {
        x += element.offsetLeft;
        y += element.offsetTop;
        element = element.offsetParent;
	 } while (element);
	 // Position blocklyDiv over blocklyArea.
	 blocklyDiv.style.left = x + 'px';
	 blocklyDiv.style.top = y + 'px';
	 blocklyDiv.style.width = blocklyArea.offsetWidth + 'px';
	 blocklyDiv.style.height = blocklyArea.offsetHeight + 'px';
};

window.addEventListener('resize', onresize, false);
onresize ();

function runCode() {
    // Generate JavaScript code and run it.
    window.LoopTrap = 1000 * 1000;
    Blockly.JavaScript.INFINITE_LOOP_TRAP = 'if (--window.LoopTrap == 0) throw "Infinite loop.";\n';
    var code = Blockly.JavaScript.workspaceToCode(workspace);
    Blockly.JavaScript.INFINITE_LOOP_TRAP = null;
    try {
        eval(code);
    } catch (e) {
        alert(e);
    }
}
