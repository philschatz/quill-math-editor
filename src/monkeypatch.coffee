Quill = require 'quill'

_           = Quill.require 'lodash'
dom         = Quill.require 'dom'
# Getting access to the following requires a custom version of quill that exposes these internals
Normalizer  = Quill.require 'normalizer'
Line        = Quill.require 'core/line'
Leaf        = Quill.require 'core/leaf'
Format      = Quill.require 'core/format'

throw new Error('BUG: Need a custom version of Quill that exposes normalizer') unless Normalizer

Quill.DEFAULTS.formats.push('math')

# Add math to the default formats so the paste-manager div can handle them instead of just stripping the math span out
Format.FORMATS['math'] =
  attribute: 'data-math'
  tag: 'SPAN'


# Monkeypatch normalizer to keep katex styles in math elements
matches = (el, selector) ->
  m = el.matches || el.matchesSelector || el.msMatchesSelector || el.mozMatchesSelector || el.webkitMatchesSelector || el.oMatchesSelector
  return false unless m # For text nodes it's always false
  return m.call(el, selector)


Normalizer_whitelistStyles = Normalizer.whitelistStyles
Normalizer.whitelistStyles = (node) ->
  # Check parents of the node to see if it is inside a 'katex' span
  return if matches(node, '[data-math] *')
  Normalizer_whitelistStyles(node)


Normalizer_optimizeLine = Normalizer.optimizeLine
Normalizer.optimizeLine = (lineNode) ->
    # Removes unnecessary tags but does not modify line contents
    lineNode.normalize()
    lineNodeLength = dom(lineNode).length()
    nodes = dom(lineNode).descendants()
    while nodes.length > 0
      node = nodes.pop()
      continue unless node?.parentNode?
      continue if dom.EMBED_TAGS[node.tagName]?
      if node.tagName == dom.DEFAULT_BREAK_TAG
        # Remove unneeded BRs
        dom(node).remove() unless lineNodeLength == 0
      else if dom(node).length() == 0 and not matches(node, '[data-math] *')
        nodes.push(node.nextSibling)
        dom(node).unwrap()
      else if node.previousSibling? and node.tagName == node.previousSibling.tagName
        # Merge similar nodes
        if _.isEqual(dom(node).attributes(), dom(node.previousSibling).attributes())
          nodes.push(node.firstChild)
          dom(node.previousSibling).merge(node)


# Line_buildLeaves = Line::buildLeaves
# Line::buildLeaves = (node, formats) ->
#   if matches(node, '[data-math]')
#     # Strip the HTML child nodes so the range/leaf calculator works, but then put the rendered katex output back
#     # node.classList.remove('loaded')
#     # innerHTML = node.innerHTML
#     # node.innerHTML = node.textContent
#     Line_buildLeaves.apply(@, arguments)
#     # node.innerHTML = innerHTML
#   else
#     Line_buildLeaves.apply(@, arguments)


Line_findLeaf = Line::findLeaf
Line::findLeaf = (leafNode) ->
  found = Line_findLeaf.apply(@, arguments)
  if found?
    return found
  else
    # Slow check. Check all the ancestors (for rendered math nodes)
    leafNodeDom = dom(leafNode)
    curLeaf = this.leaves.first
    while curLeaf?
      if leafNodeDom.isAncestor(curLeaf.node)
        return curLeaf
      curLeaf = curLeaf.next


Leaf_isLeafNode = Leaf.isLeafNode
Leaf.isLeafNode = (node, formats) ->
  return true if matches(node, '[data-math] .katex')
  return Leaf_isLeafNode.apply(@, arguments)
