import Utils from './utils'
import createElementDefinition from './element'

registerComponent: (tag, {props, styles, BaseElement=HTMLElement, scopeCSS=true}, extension) -> (ComponentType) ->
  return console.error 'Component missing static tag property' unless tag
  Utils.normalizePropDefs(props)
  element = createElementDefinition({
    BaseElement, ComponentType, propDefinition: props, childStyles: styles, scopeCSS
  })
  customElements.define(tag, element, extension)
  element

export { Utils, ComponentElement, registerComponent}