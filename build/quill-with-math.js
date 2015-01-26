// Generated by CoffeeScript 1.7.1
(function() {
  var MONKEYPATCH, MathTooltipFn, Quill;

  Quill = require('quill');

  MathTooltipFn = require('./math-tooltip');

  MONKEYPATCH = require('./monkeypatch');

  module.exports = function(katex) {
    var MathTooltip;
    MathTooltip = MathTooltipFn(katex);
    Quill.registerModule('math-tooltip', MathTooltip);
    return Quill;
  };

}).call(this);
