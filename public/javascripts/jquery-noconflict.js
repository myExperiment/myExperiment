jQuery.noConflict();

Element.Methods.hide = function(element) {
    element = $(element);
    if(!isBootstrapEvent)
    {
        element.style.display = 'none';
    }
    return element;
};
