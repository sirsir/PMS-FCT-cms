
function fncShowDialog(form, pop_box_id, msg)
{
    var main_doc = fncGetMainDocument();
    var pop_box = main_doc.getElementById(pop_box_id);

    if (!Prototype.Browser.IE) {
        pop_box.style.position = "fixed";
        pop_box.style.left = "0px";
        pop_box.style.top = "0px";
    }

    pop_box.style.display = "block";

    pop_box.innerHTML = msg;
}

function fncHideDialog(pop_box_id)
{
    var main_doc = fncGetMainDocument();
    var pop_box = main_doc.getElementById(pop_box_id);

    if (pop_box != null) {
        pop_box.style.display = "none";
    }
}

function fncPrepareFormForSubmit(form)
{
    selectedOption(form);
    fncClearErr();

    var main_doc = fncGetMainDocument();
    var frm_content = main_doc.getElementById(form.id + "_content");

    fncSetNumericFormatToSave(form);

    if (frm_content == null) {
        frm_content = form;
    }
    
    fncShowDialog(frm_content, "pop_box", "<img src='/images/progress.gif' />");
}

function fncActivate(frm){
    if (frm.getAttribute("original_inner_html")=="") {
        frm.setAttribute("original_inner_html", frm.innerHTML);
    }
}

function fncReset(frm) {
    frm.innerHTML = frm.getAttribute("original_inner_html");
}

function fncGetTempFrame(){
    var i;
    for (i=0; i<window.parent.frames.length; i++) {
        if (window.parent.frames[i].name == "tmp_frame") {
            return window.parent.frames[i];
        }
    }

    return null;
}

function fncGetTempDocument(){
    var tmpFrame = fncGetTempFrame();

    if (tmpFrame != null) {
        return tmpFrame.document
    }

    return null;
}

function fncGetMainDocument(){
    var i;
    for (i=0; i<window.parent.frames.length; i++) {
        if (window.parent.frames[i].name == "main_frame") {
            return window.parent.frames[i].document;
        }
    }

    return null;
}

function fncCopyHTMLToForm(form_content_id) {
    var main_document = fncGetMainDocument();
    var tmp_document = fncGetTempDocument();

    var src_div = main_document.getElementById(form_content_id);
    var tmp_frm = tmp_document.getElementById("tmp_form_id");

    if (tmp_frm == null)  {
        alert("Application not ready. Please try again later.");
        return;
    }

    tmp_frm.action = src_div.getAttribute("action");

    var oNewNode;
    if (Prototype.Browser.IE6 || Prototype.Browser.IE7) {
        oNewNode = tmp_document.createElement("DIV");
        oNewNode.innerHTML = src_div.outerHTML;
    }
    else {
        oNewNode = src_div.cloneNode(true);
    }
    tmp_frm.appendChild(oNewNode);

    // Sync the selected options and selected value
    var tmp_selects = tmp_document.getElementsByTagName("select");
    var i,j;
    for (i = 0; i < tmp_selects.length; i++) {
        var tmp_select = tmp_selects[i];
        var select = main_document.getElementById(tmp_select.id);
        tmp_select.value = select.value;

    // ToDo: Select option for multi-select
    }

    // Sync the input controls
    var tmp_inputs = tmp_document.getElementsByTagName("input");
    for (i = 0; i < tmp_inputs.length; i++) {
        var tmp_input = tmp_inputs[i];

        if (tmp_input.id == null || tmp_input.id == ""
            || tmp_input.type == "hidden" || tmp_input.value == null) continue;

        var input = main_document.getElementById(tmp_input.id);
        
        if (["checkbox", 'radio'].include(tmp_input.type)) {
            tmp_input.checked = input.checked;
        }
        else {
            tmp_input.value = input.value;
        }
        
    // ToDo: Select option for multi-select
    }

    // Sync password
    if (null != main_document.getElementById("password"))
    {
        tmp_document.getElementById("password").value = main_document.getElementById("password").value;
    }

    tmp_frm.submit();
}

function fncCopyResultToMainFrame(form_content_id, div_id) {
    var main_document = fncGetMainDocument();

    var src_div = document.getElementById(form_content_id);
    var div = main_document.getElementById(div_id);

    div.innerHTML = src_div.innerHTML;
}

function fncClearDiv(div)
{
    if (div != null) {
        while (div.firstChild) {
            div.removeChild(div.firstChild);
        }
    }
}


function fncSetDivContent(div_id, text, yaml)
{
    var main_doc = fncGetMainDocument();
    var div_text = main_doc.getElementById(div_id + "_text");
    var hidden_yaml = main_doc.getElementById(div_id + "_yaml");
    
    div_text.innerHTML = text;
    hidden_yaml.value = yaml;
}

function fncCheckTempFormForException(){
    var tmp_document = fncGetTempDocument();

    if (tmp_document == null || tmp_document.body == null) return;
    
    var sBody = tmp_document.body.innerHTML;
    if (sBody.indexOf("Application Trace | Framework Trace | Full Trace") > -1) {
        fncSetError(sBody.replace("'", "&rsquo;"));
    } 
}

function checkFileExtension(txt_file, select_type_id)
{
    var filePath = txt_file.value;

    if(filePath.indexOf('.') == -1)
        return false;
        
    var ext = filePath.substring(filePath.lastIndexOf('.') + 1).toLowerCase();
    var select_type = document.getElementById(select_type_id);
    if (ext == select_type.value.toLowerCase())
    {
        return true;
    }
    else {
        alert('The file extension ' + ext.toUpperCase() + ' is not allowed!');
        return false;
    }
}
