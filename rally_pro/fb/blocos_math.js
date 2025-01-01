/**
 * https://blockly-demo.appspot.com/static/demos/blockfactory/index.html#oteaus
 */

Blockly.Blocks['mymath_intdiv'] = {
  init: function() {
    this.setHelpUrl(null);
    this.setColour(240);
    this.appendDummyInput()
        .appendField("quociente divisão de");
    this.appendValueInput("NUMBER")
        .setCheck("Number");
    this.appendDummyInput()
        .appendField("por 10");
    this.setInputsInline(true);
    this.setOutput(true, "Number");
    this.setTooltip('');
  }
};

Blockly.JavaScript['mymath_intdiv'] = function(block) {
  var value_number = Blockly.JavaScript.valueToCode(block, 'NUMBER', Blockly.JavaScript.ORDER_ATOMIC);
  var code = 'Math.trunc ((' + value_number + ') / 10)';
  return [code, Blockly.JavaScript.ORDER_DIVISION];
};


/**
 * https://blockly-demo.appspot.com/static/demos/blockfactory/index.html#oteaus
*/

Blockly.Blocks['mymath_intrem'] = {
  init: function() {
    this.setHelpUrl(null);
    this.setColour(240);
    this.appendDummyInput()
        .appendField("resto divisão de");
    this.appendValueInput("NUMBER")
        .setCheck("Number");
    this.appendDummyInput()
        .appendField("por 10");
    this.setInputsInline(true);
    this.setOutput(true, "Number");
    this.setTooltip('');
  }
};

Blockly.JavaScript['mymath_intrem'] = function(block) {
  var value_number = Blockly.JavaScript.valueToCode(block, 'NUMBER', Blockly.JavaScript.ORDER_ATOMIC);
  var code = '((' + value_number + ') % 10)';
  return [code, Blockly.JavaScript.ORDER_DIVISION];
};
