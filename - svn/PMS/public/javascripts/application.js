function fncToggleLeftPanel(){
    var panel = document.getElementById("left_panel");

    fncTogglePanel(panel);
}

function fncToggleSearchPanel(){
    var panel = document.getElementById("left_panel_tab_filter_content");

    fncTogglePanel(panel);
}

function fncTogglePanel(panel){
    if (panel.style.display=='' || panel.style.display=='block') {
        panel.style.display='none';
    }
    else {
        panel.style.display='';
    }

    createCookie(panel.id, panel.style.display, 24*7);
}

function fncSetOperationForm(strUrl){
    fncAjaxUpdater('operation_area', strUrl);
}

function fncSetRelationForm(strUrl){
    fncAjaxUpdater('relation_area', strUrl);
}

function fncSetSearchForm(strUrl){
    fncAjaxUpdater('left_panel_tab_filter_content', strUrl);
}

//  create by   : S.Jitta
//  create when : 09/09/2009
//  porpose     : use for quick add
function fncQuickAdd(referenceAreaId, strUrl){
    var sValue  = prompt("Please enter your value","");
    if(sValue != null && sValue.trim() != "")
    {
        strUrl = strUrl.replace("JAVASCRIPT_VAR_NAME",sValue.trim());
        fncAjaxUpdater(referenceAreaId, strUrl);
    }
}

var _suggest_timer = 0;
function fncQuickSearch(resultAreaId, strUrl, e, result_row_id){
    if (_suggest_timer > 0)
    {
        clearTimeout(_suggest_timer);
    }
    if (e.value != e.getAttribute('last_value')){ 
        var r = document.getElementById(resultAreaId);
        r.innerHTML = "";
        r.className = r.className.replace("_hidden", "");
        
        if (e.value != null && e.value.length > 2)
        {
            strUrl = strUrl.replace("JAVASCRIPT_VAR_TEXT", escape(e.value)); // e.value
            strUrl = strUrl.replace("JAVASCRIPT_VAR_ID", e.id);
            strUrl = strUrl.replace("JAVASCRIPT_VAR_RESULT_ROW_ID", result_row_id);
            _suggest_timer = setTimeout("fncAjaxUpdater('" + resultAreaId + "','" + strUrl + "')", 500);
        }
        else {
            r.className +='_hidden';
        }

        $(result_row_id).value = "";
        
        e.setAttribute('last_value', e.value)
    }
}

function fncResetQuickSearchText(resultAreaId, e, result_row_id){
    if ($(result_row_id + "_row_id").value == "") $(resultAreaId).value = "";
    var r = document.getElementById(resultAreaId);
    r.innerHTML = "";
    r.className +='_hidden';
}

var _suggest_timer2 = 0;
function fncQuickSearchRef(resultAreaId, strUrl, e, from_cf_id, relate_to){
    if (_suggest_timer2 > 0)
    {
        clearTimeout(_suggest_timer2);
    }
    if (e.value != null && e.value.length > 2)
    {
        strUrl = strUrl.replace("JAVASCRIPT_VAR_TEXT", escape(e.value)); // e.value
        strUrl = strUrl.replace("JAVASCRIPT_VAR_ID", e.id);
        strUrl = strUrl.replace("JAVASCRIPT_VAR_RESULT_ROW_ID", "cells[" + from_cf_id + "]_row_id");
        strUrl = strUrl + "&from_cf_id=" + from_cf_id;
        strUrl = strUrl + "&relate_to=" + relate_to;
        _suggest_timer2 = setTimeout("fncAjaxUpdater('" + resultAreaId + "','" + strUrl + "')", 500);
        var r = document.getElementById(resultAreaId);
        r.className = r.className.replace("_hidden", "");
    }
}

function fncSetSuggestedValue(inputId, value, suggestDiv, result_row_id, row_id){
    // Setting text and id , Hidding the search space
    var e = document.getElementById(inputId);
    e.value = value;
    e.setAttribute('last_value', e.value)
    suggestDiv.className +='_hidden';
    document.getElementById(result_row_id).value = row_id;
}

function fncSetSuggestedValueRef(inputId, value, suggestDiv, result_row_id, row_id, relate_to, from_cf_id){
    fncSetSuggestedValueRef(inputId, value, suggestDiv, result_row_id, row_id, relate_to, from_cf_id, 0);
}

function fncSetSuggestedValueRef(inputId, value, suggestDiv, result_row_id, row_id, relate_to, from_cf_id, screen_id){
    // Setting text and id , Hidding the search space
    document.getElementById(inputId).value = value;
    suggestDiv.className +='_hidden';
    document.getElementById(result_row_id).value = row_id;

    // Reloading combo box
    var area = "cells_div_" + relate_to;
    var url = "/rows/reload_comboref/0?custom_field_id=" + relate_to +
        "&row_id=" + row_id +
        "&from_cf_id=" + from_cf_id;
    url += (screen_id > 0 ) ? "&screen_id=" + screen_id : "";

    fncAjaxUpdater(area,url);
}

function ResetTextBox(val)
{
    text = document.getElementById(val);
    text.value = "";
    return false;
}

function fncReloadComboRef(val, e, from_cf_id){
    fncReloadComboRef(val, e, from_cf_id, 0);
}

function fncReloadComboRef(val, e, from_cf_id, screen_id){
    // Reloading combo box
    var area = "cells_div_" + val;
    var url = "/rows/reload_comboref/0?custom_field_id=" + val + 
        "&row_id=" + e.value + 
        "&from_cf_id=" + from_cf_id;
    url += (screen_id > 0 ) ? "&screen_id=" + screen_id : "";

    fncAjaxUpdater(area,url);
}

function fncLeftToRightRefernce(referenceAreaId, list_id, strUrl){
    var nScreenId = -1;
    var l = document.getElementById(list_id);

    if(l.options.length > 0){
        nScreenId = l.options[l.options.length-1].value;
    }
    strUrl = strUrl.replace("JAVA_SCRIPTION_VAR_SCREEN_ID", nScreenId);
    fncAjaxUpdater(referenceAreaId, strUrl);
}

function fncGenTextbox(){

    var cmbExpression = document.getElementById("cmbExpression");
    var i;
    
    if (cmbExpression.value){

        var START_FIELD = 'field[value][formula]';
        var div = document.getElementById("combined_formula");
        var fnc;
        var inputs = document.getElementsByTagName("input");
        for (i = 0; i < inputs.length; i++) {
            input = inputs[i];
            if (input.name == "rdoOperation") {
                if (input.checked) {
                    fnc = input.value;
                    break;
                }
            }
        }

        var hdfOperation = document.createElement("input");
        var hdfValue = document.createElement("input");
        var hdfValue2 = document.createElement("input");

        hdfOperation.type = "hidden";
        var OperationId =  fncName2Id(START_FIELD + cmbExpression.value);
        hdfOperation = document.getElementById(OperationId);
        hdfOperation.value = fnc;

        hdfValue.type = "hidden";
        hdfValue2.type = "hidden";

        var option_value1, option_value2;

        if (["ADD", "SUB", "MUL", "DIV", "FLR", "CEL", "AND", "OR", "CCT"].include(fnc)){
            div.appendChild(hdfOperation);

            option_value1 = cmbExpression.value.replace('[fnc]','[var_1][fnc]');
            option_value2 = cmbExpression.value.replace('[fnc]','[var_2][fnc]');
            cmbExpression.remove(cmbExpression.selectedIndex);
            
            //Value Var1            
            cmbExpression.options[cmbExpression.length] = new Option(option_value1, option_value1);

            hdfValue.name = START_FIELD + option_value1;
            hdfValue.id = fncName2Id(hdfValue.name);
            hdfValue.value = option_value1;

            //Value Var2
            cmbExpression.options[cmbExpression.length] = new Option(option_value2, option_value2);

            hdfValue2.name = START_FIELD + option_value2;
            hdfValue2.id = fncName2Id(hdfValue2.name);
            hdfValue2.value = option_value2;

            fncSortListbox(cmbExpression);
            div.appendChild(hdfValue);
            div.appendChild(hdfValue2);

        }
        else if (["CNS", "VAR"].include(fnc)) {
            hdfValue.name = START_FIELD +  cmbExpression.value.replace('[fnc]','[var_1]');
            hdfValue.id = fncName2Id(hdfValue.name);
            if ("CNS" == fnc){
                var txtCNS = document.getElementById("txtCNS");
                hdfValue.value = txtCNS.value;
            }
            else if ("VAR" == fnc){
                var cmbVAR = document.getElementById("cmbVAR");
                hdfValue.value = cmbVAR.value;
            }
            div.appendChild(hdfValue);
            cmbExpression.remove(cmbExpression.selectedIndex);
        }
        else if ("DAT" == fnc){
            var cmbDAT_FNC = document.getElementById("cmbDAT_FNC");
            var cmbDAT_VAR = document.getElementById("cmbDAT_VAR");

            hdfValue.value = cmbDAT_FNC.value;
            hdfValue.name = START_FIELD +  cmbExpression.value.replace('[fnc]','[var_1]');
            hdfValue.id = fncName2Id(hdfValue.name);

            hdfValue2.value = cmbDAT_VAR.value;
            hdfValue2.name = START_FIELD +  cmbExpression.value.replace('[fnc]','[var_2]');
            hdfValue2.id = fncName2Id(hdfValue.name);

            div.appendChild(hdfValue);
            div.appendChild(hdfValue2);
            cmbExpression.remove(cmbExpression.selectedIndex);
        }
        else if ("NOT" == fnc){
            div.appendChild(hdfOperation);

            option_value1 = cmbExpression.value.replace('[fnc]','[var_1][fnc]');
            cmbExpression.remove(cmbExpression.selectedIndex);

            cmbExpression.options[cmbExpression.length] = new Option(option_value1, option_value1);
            
            hdfValue.name = START_FIELD +  option_value1;
            hdfValue.id = fncName2Id(hdfValue.name);
            hdfValue.value = option_value1;
            
            fncSortListbox(cmbExpression);
            div.appendChild(hdfValue);
        }
        
        fncCopyHTMLToForm("combined_formula");
    }

    cmbExpression.selectedIndex = 0;
    for (i = 0; i < cmbExpression.length; i++) {
        if (cmbExpression.options[i].value == option_value1) {
            cmbExpression.selectedIndex = i;
            break;
        }
    }
}

function fncResetTextbox(){
    var START_FIELD = 'field[value][formula]';
    var div = document.getElementById("combined_formula");
    var div_text = document.getElementById("combined_formula_result_text");
    var hidden_yaml = document.getElementById("combined_formula_result_yaml");
    var cmbExpression = document.getElementById("cmbExpression");
    for(i=cmbExpression.options.length-1;i>=0;i--)
    {
        cmbExpression.remove(i);
    }
    cmbExpression.options[cmbExpression.length] = new Option('[fnc]','[fnc]');
    cmbExpression.selectedIndex = 0;
    var txtCNS = document.getElementById("txtCNS");
    txtCNS.value = "";
    div_text.innerHTML = "...";
    hidden_yaml.value = "";
    var inputs = document.getElementsByTagName("input");
    for (var i = 0; i < inputs.length; i++) {
        input = inputs[i];
        if ((input.name).indexOf("field[value][formula]",0) !=-1) {
            var txtTMP = document.getElementById(fncName2Id(input.name));
            div.removeChild(txtTMP);
            i=i-1;
        }
    }

    var hdfOperation = document.createElement("input");
    hdfOperation.type = "hidden";
    var OperationId =  fncName2Id(START_FIELD + "[fnc]");
    hdfOperation.name = START_FIELD +  "[fnc]";
    hdfOperation.id = OperationId;
    hdfOperation.value = "[fnc]";
    div.appendChild(hdfOperation);
}

function fncControlOperation(){
    var fnc;
    var inputs = document.getElementsByTagName("input");
    for (var i = 0; i < inputs.length; i++) {
        input = inputs[i];
        if (input.name == "rdoOperation") {
            if (input.checked) {
                fnc = input.value;
                break;
            }
        }
    }
    var txtCNS = document.getElementById("txtCNS");
    var cmbVAR = document.getElementById("cmbVAR");
    var cmbDAT_FNC = document.getElementById("cmbDAT_FNC");
    var cmbDAT_VAR = document.getElementById("cmbDAT_VAR");
    if (fnc == "CNS"){
        txtCNS.disabled= false;
        cmbVAR.disabled = true;
        cmbDAT_FNC.disabled = true;
        cmbDAT_VAR.disabled = true;
    }
    else if (fnc == "VAR"){
        txtCNS.disabled= true;
        cmbVAR.disabled = false;
        cmbDAT_FNC.disabled = true;
        cmbDAT_VAR.disabled = true;
    }
    else if (fnc == "DAT"){
        txtCNS.disabled= true;
        cmbVAR.disabled = true;
        cmbDAT_FNC.disabled = false;
        cmbDAT_VAR.disabled = false;
    }else{
        txtCNS.disabled= true;
        cmbVAR.disabled = true;
        cmbDAT_FNC.disabled = true;
        cmbDAT_VAR.disabled = true;
    }
}

function fncName2Id(name){
    while (name.indexOf("][") >=0) name = name.replace("][", "_");
    return name.replace("[","_").replace("]","");
}

function AddItem(objListBox, strText){
    var newOpt = document.createElement("OPTION");
    newOpt.innerHTML = strText;
    newOpt.value = strText;
    objListBox.options.add(newOpt);
}

function RemoveItem(objListBox, strId){
    var intIndex = GetItemIndex(objListBox, strId);
    if (intIndex != -1)
        objListBox.remove(intIndex);
}

function fncSortListbox(objListBox) {

    arrTexts = new Array();

    for(i=0; i<objListBox.length; i++)  {
        arrTexts[i] = objListBox.options[i].text;
    }

    arrTexts.sort();

    for(i=0; i<objListBox.length; i++)  {
        objListBox.options[i].text = arrTexts[i];
        objListBox.options[i].value = arrTexts[i];
    }
}

//  create by   : S.Jitta
//  create when : 10/02/2009
//  porpose     : use when you want to load default after AjaxUpdater
function fncOnLoadAfterAjaxUpdater(){
    var objDivs = document.getElementsByTagName("div");
    
    for(i=0; i< objDivs.length; i++) {
        div = objDivs[i];
        div_name = div.getAttribute("name");

        if (["on_load_operation_content", "on_load_relation_content", "on_load_field_content", "on_load_default_tab_content", "on_load_report_content"].include(div_name)) {
            if (div_name == "on_load_relation_content" && readCookie("auto_load_relation_content") != "true") {
                continue;
            }
            
            if (div.getAttribute("status") == "unloaded" ){
                div.setAttribute("status", "loaded");

                ajax_call_mode = div.getAttribute("ajax_call_mode");
                if (ajax_call_mode == "request") {
                    new Ajax.Request(div.getAttribute("ajax_url"), {asynchronous:true, evalScripts:true});
                }
                else{
                    fncAjaxUpdater(div.getAttribute("ajax_result_id"), div.getAttribute("ajax_url"));
                }
            }

        }
        else if (div_name == "on_load_row_content") {
            if (div.getAttribute("ajax_status") == "unloaded" ){
                div.setAttribute("ajax_status", "loaded");

                fncAjaxUpdater_ReplaceTR(div.getAttribute("ajax_result_id"), div.getAttribute("ajax_url"));
            }
        }
        else if (div_name == "relation_area") {
            var checkbox = document.getElementById("auto_load_relation_content");
            if (checkbox != null) {
                checkbox.checked = readCookie("auto_load_relation_content") == "true";
                fncToggleRelationArea("relation_area", checkbox);
            }
        }
    }
}

function fncResetUnloaded(div_ids){
    var main_doc = fncGetMainDocument();
    for (i=0; i< div_ids.length; i++) {
        var div = main_doc.getElementById(div_ids[i]);
        div_name = div.getAttribute("name");
        if (div.getAttribute("status") == "loaded" )
            {div.setAttribute("status", "unloaded");}
    }
}
//  create by   : S.Jitta
//  create when : 21/01/2009
//  porpose     : scroll the page to div that load from AjaxUpdater
function fncScrollIntoView(strDivId){
    var main_doc = fncGetMainDocument();
    e = main_doc.getElementById(strDivId);
    ea = main_doc.getElementById(strDivId + '_anchor');
    if (ea != null) {
        ea.click();
    } else if (e.getAttribute("scroll_in_to_view")) {
        e.scrollIntoView(true);
    }
}

//By nong
function fncSetSubMenu(display_menu_ids, select_menu_ids){

    var __isIE =  navigator.appVersion.match(/MSIE/);

    if (__isIE && display_menu_ids.length > 0) {
        var c = document.getElementById(display_menu_ids[0]);

        if (display_menu_ids.length > 1) {
            c.parentNode.parentNode.setAttribute('handle_fncSetSubMenu', 'false');
        }
        var handle_fncSetSubMenu = c.getAttribute('handle_fncSetSubMenu') != 'false';
        c.setAttribute('handle_fncSetSubMenu', 'true');

        if (!handle_fncSetSubMenu) return;
    }

    var BlindEffectDuration = 0.5;

    // Get all of the DIV elements, will filter menu div later
    var elements = document.getElementsByTagName("div");
    for (i=0; i< elements.length; i++)
    {
        // Filter the non-menu items
        // Don't hide the items that will be shown
        if (elements[i].id.length > 4
            && elements[i].id.substring(0,4) == "menu") {
            menu = elements[i];
            if (display_menu_ids.indexOf(menu.id) == -1) {
                if ( menu.getAttribute("state") != "closed"
                    && menu.getAttribute("always_show")!="true") {
                    new Effect.BlindUp(menu.id, {
                        duration: BlindEffectDuration
                    });
                    menu.setAttribute("state", "closed");
                }
            }
            
            menu.className = menu.className.replace("_hover", "").replace("_selected", "");
        }
    }
    
    // Show the items in the list
    // Don't re-show the already shown items
    for (i=0; i< display_menu_ids.length; i++){
        menu = document.getElementById(display_menu_ids[i]);
        if (menu != null) {

            if (menu.getAttribute("state") == "closed"){
                new Effect.BlindDown(menu.id, {
                    duration: BlindEffectDuration
                });
                menu.setAttribute("state", "opened");
            }
            if (select_menu_ids.indexOf(menu.id) >= 0) {
                fncAppendClassName(menu, "_selected");
            }
        }
    }
}

//  for deselecting previous selected submenu
function fncDeselectedMenuItem(){
    var itm = document.getElementsByTagName("div");
    for(i = 0; i < itm.length; i++){
        if (itm[i].className.substring(0,4) == "menu") {
            itm[i].className = itm[i].className.replace("_hover", "").replace("_selected", "");
        }
    }
}

function fncSetSelectedMenuItem(select_menu_ids){
    fncDeselectedMenuItem();
    
    for(i = 0; i < select_menu_ids.length; i++){
        var itm = document.getElementById(select_menu_ids[i]);
        fncAppendClassName(itm, "_selected");
    }
}

function fncResetInvalidSearch(){
    var search_tab_element = document.getElementById("search_tab");
    var div_elements = search_tab_element.getElementsByTagName("div");
    for(i = 0; i < div_elements.length; i++){
        if (div_elements[i].className == "search_invalid") {
            div_elements[i].className = div_elements[i].className.replace("_invalid", "");
            div_elements[i].title = "";
        }
    }
}

function fncSubmitSearch() {
    fncAjaxAbort();
    fncSetElementInnerHtml("main", "<img src='/images/loading.gif'>&nbsp;Loading... ");

    fncResetInvalidSearch();
}

function fncClearInvalidSearch(cf_id){
    var main_doc = fncGetMainDocument();
    var cf_name = "custom_fields_" + cf_id;
    var cf = main_doc.getElementById(cf_name + "_filter");

    cf.className = cf.className.replace("_invalid", "");
    cf.title = "";
}

function fncSetInvalidSearch(arr_cf_required,arr_cf_invalid){
    var main_doc = fncGetMainDocument();
    var arr_cf = arr_cf_required.concat(arr_cf_invalid);
    for(i = 0 ; i <= arr_cf.length-1 ; i++)
    {
        fncClearInvalidSearch(arr_cf[i]);
        
        var cf_name = "custom_fields_" + arr_cf[i];
        var cf = main_doc.getElementById(cf_name + "_filter");
        
        cf.className += "_invalid";
            if (i <= arr_cf_required.length-1)
            cf.title = "Required Search";
            else
            cf.title = "Invalid Format";
   
    } 
}

function fncClearComboBoxDateFormat(date_format,field_month_id,field_year_id,hidden_tag_id,default_value){
    (document.getElementById(hidden_tag_id)).value = default_value;
    (document.getElementById(field_year_id)).value = "";
    if (date_format != "year"){
        if (date_format == "half_year" || date_format == "quarter_year")
            (document.getElementById(field_month_id)).value = "0";
        else
            (document.getElementById(field_month_id)).value = "";
    }
    
    return false;
}

function fncLoadAjaxByScreenId(url_main,url_search){
    fncAjaxAbort();
    fncAjaxUpdater("main", url_main);
    fncAjaxUpdater("left_panel_tab_filter_content", url_search);
}
function fncLoadAjaxByScreenIdFind(url_main,url_search){
    fncOnCilckTab('left_panel_tab_filter');
    fncAjaxAbort();
    fncAjaxUpdater("main", url_main);
    fncAjaxUpdater("left_panel_tab_filter_content", url_search);
}

function fncOnMenuItemClicked(screen_id){
    fncLoadAjaxByScreenId("/screens/" + screen_id,"/screens/search/" + screen_id);
    fncSetSelectedMenuItem([screen_id]);
}

function fncBlindGroup(anchor, blinding_image_id, content_id){
    var src = "";
    var display = "";

    if (anchor.getAttribute("blinding_state") == '0') {
        src = "/images/blind_up.gif";
        display = "block";

        anchor.setAttribute("blinding_state", '1');
    }
    else {
        src = "/images/blind_down.gif";
        display = "none";

        anchor.setAttribute("blinding_state", '0');
    }

    document.getElementById(blinding_image_id).src = src;
    document.getElementById(content_id).style.display = display;
}

function onSelectableItemMouseEnter(){
    if (this.className.indexOf("_selected")<0)
        fncAppendClassName(this, "_hover");
}

function onSelectableItemMouseLeave(){
    this.className = this.className.replace("_hover", "");
}

function fncDeselectTableContentTr(eventOwner){
    var tr_elements = document.getElementsByTagName("tr");
    for(i = 0; i < tr_elements.length; i++){

        tr = tr_elements[i];
        if (eventOwner!=tr && ['tr_odd_selected', 'tr_even_selected', 'tr_new_selected', 'tr_edit_selected'].include( tr.className ) ) {
            tr.className = tr.className.replace("_selected", "");
        }
    }
}

function onTableContentTrClick(){
    fncDeselectTableContentTr(this);
    this.className = this.className.replace("_hover", "");

    var handleonclick = this.getAttribute("handleonclick");
    var pre_ajax_result_id = this.getAttribute("pre_ajax_result_id");
    var pre_ajax_url = this.getAttribute("pre_ajax_url");
    var operation_url = this.getAttribute("operation_url");
    var operation_area = this.getAttribute("operation_area");
    var relation_url = this.getAttribute("relation_url");
    var relation_area = this.getAttribute("relation_area");
    var field_url = this.getAttribute("field_url");
    var field_area = this.getAttribute("field_area");
    var post_ajax_result_id = this.getAttribute("post_ajax_result_id");
    var post_ajax_url = this.getAttribute("post_ajax_url");

    if (handleonclick == "true") {
        fncAppendClassName(this, "_selected");

        if (pre_ajax_result_id  != "" && pre_ajax_url != ""){
            fncAjaxUpdater(pre_ajax_result_id, pre_ajax_url);
        }
        if (operation_url  != "" && operation_area != ""){
            fncAjaxUpdater(operation_area, operation_url);
        }
        if (relation_url  != "" && relation_area != ""){
            fncAjaxUpdater(relation_area, relation_url);
        }
        if (field_url != null && field_area != null){
            if (field_url  != "" && field_area != ""){
                fncAjaxUpdater(field_area, field_url);
            }
        }
        if (post_ajax_result_id  != "" && post_ajax_url != ""){
            fncAjaxUpdater(post_ajax_result_id, post_ajax_url);
        }
    }
    else {
        if (operation_area != "" && operation_area != null){
            var o = document.getElementById(operation_area);
            o.innerHTML = "";
        }
        if (relation_area != "" && relation_area != null){
            var r = document.getElementById(relation_area);
            r.innerHTML = "";
        }
    }

    this.setAttribute("handleonclick", "true");
    
    fncClearErr();
}

function onGroupSelectAllClick(){
    var strGroupPrefix = this.id.replace('_select_all','_check_');
    for(i = 0; i < document.all.length; i++)
    {
        itm = document.all(i);
        if(itm.id.search(strGroupPrefix)!=-1) {
            itm.checked = this.checked;
            itm.onclick();
        }
    }
}

function fncHighLight(checked,tr_id) {
    if (checked)
        document.getElementById(tr_id).style.backgroundColor = "#00CCFF";
    else
        document.getElementById(tr_id).style.backgroundColor = "";
}

function fncHighLightTopic(checked,tr_id){
    fncHighLight(checked,tr_id + "_1");
    fncHighLight(checked,tr_id + "_2");
    fncHighLight(checked,tr_id + "_3");
}

/*
Assign event handling for the items in the page
*  - tr
*/
function fncSetObjectEvent(){
    fncSetAllTrEvent(document.getElementsByTagName("tr"));
    fncSetAllLiEvent(document.getElementsByTagName("li"));
    fncSetAllDivEvent(document.getElementsByTagName("div"));
    fncSetAllInputEvent(document.getElementsByTagName("input"));
}

function fncSetAllTrEvent(tr_elements){
    for(i = 0; i < tr_elements.length; i++) fncSetTrEvent(tr_elements[i]);
}

function fncSetAllLiEvent(li_elements){
    for(i = 0; i < li_elements.length; i++) fncSetLiEvent(li_elements[i]);
}

function fncSetAllDivEvent(div_elements){
    for(i = 0; i < div_elements.length; i++) fncSetDivEvent(div_elements[i]);
}

function fncSetAllInputEvent(input_elements){
    for(i = 0; i < input_elements.length; i++) fncSetInputEvent(input_elements[i]);
}

/*
Assign event handling for the items in the page
*  - tr_event
*  - tr_odd
*/
function fncSetTrEvent(tr){
    if (['tr_odd', 'tr_even','tr_new', 'tr_edit'].include( tr.className ) && tr.onmouseenter == null) {
        tr.onmouseenter = onSelectableItemMouseEnter;
        tr.onmouseleave = onSelectableItemMouseLeave;
        tr.onclick = onTableContentTrClick;

        if (tr.getAttributeNode("pre_ajax_result_id") == null && tr.getAttributeNode("pre_ajax_url") == null) {
            tr.setAttribute("pre_ajax_result_id", "");
            tr.setAttribute("pre_ajax_url", "");
        }
        else {
            if (tr.getAttributeNode("pre_ajax_result_id") == null && tr.getAttributeNode("pre_ajax_url") != null)
                fncAlertTrMissingAttribute("pre_ajax_result_id");
            if (tr.getAttributeNode("pre_ajax_result_id") != null && tr.getAttributeNode("pre_ajax_url") == null)
                fncAlertTrMissingAttribute("pre_ajax_url");
        }
        if (tr.getAttributeNode("handleonclick") == null) fncAlertTrMissingAttribute("handleonclick");
        if (tr.getAttribute("handleonclick") != "true") {
            tr.setAttribute("handleonclick", "false");
        }
        if (tr.getAttribute("handleonclick") == "true") {
            if (tr.getAttributeNode("operation_url") == null) fncAlertTrMissingAttribute("operation_url");
            if (tr.getAttributeNode("operation_area") == null) fncAlertTrMissingAttribute("operation_area");
            if (tr.getAttributeNode("relation_url") == null) fncAlertTrMissingAttribute("relation_url");
            if (tr.getAttributeNode("relation_area") == null) fncAlertTrMissingAttribute("relation_area");
        }
        if (tr.getAttributeNode("post_ajax_result_id") == null && tr.getAttributeNode("post_ajax_url") == null) {
            tr.setAttribute("post_ajax_result_id", "");
            tr.setAttribute("post_ajax_url", "");
        }
        else {
            if (tr.getAttributeNode("post_ajax_result_id") == null && tr.getAttributeNode("post_ajax_url") != null)
                fncAlertTrMissingAttribute("post_ajax_result_id");
            if (tr.getAttributeNode("post_ajax_result_id") != null && tr.getAttributeNode("post_ajax_url") == null)
                fncAlertTrMissingAttribute("post_ajax_url");
        }
    }
}

function fncAlertTrMissingAttribute(attr_name){
    throw "Please add the missing required attribute '" + attr_name + "'.";
}

/*
Assign event handling for the items in the page
*  - menu_item
*/
function fncSetLiEvent(li){
}

/*
Assign event handling for the items in the page
*  -
*/
function fncSetDivEvent(div){
    if (['menu_item'].include( div.className ) && div.onmouseenter == null) {
        div.onmouseenter = onSelectableItemMouseEnter;
        div.onmouseleave = onSelectableItemMouseLeave;
    }
}

/*
Assign event handling for the items in the page
*  -
*/
function fncSetInputEvent(input){
    if (['js_caller'].include( input.className ) && input.onclick != null) {
        if (input.getAttributeNode("clicked") == null) {
            input.setAttribute("clicked", "true");
            try {
                input.click();
                input.setAttribute("click_result", "true");
            }
            catch(err)
            {
                input.setAttribute("click_result", (err.constructor == String) ? err : err.message);
            }
        }
    }
}

function fncRemoveSelectOption(src_box_id, isSorted, isRemoveFollowings){
    // isAll => 1:all,0:selected
    // isSorted => 1:sorted,0:unsorted
    // isRemoveFollowings => 1:remove,0:keep
    var src_box = document.getElementById(src_box_id);

    var i;

    // Add the selected items to the src_box's list
    for(i = src_box.options.length - 1; i >= 0; i--) {
        var selected = (src_box.options[i].selected && src_box.options[i].value != "");

        if (isRemoveFollowings !=0 || selected) src_box.remove(i);

        if (selected) break;
    }
}

//  create by   : S.Jitta
//  create when : 25/12/2008
//  porpose     : for move selected list from one side to another side, used in application_helper
function fncMoveSelectOption(from_box_id, to_box_id, isAll, isSorted, remove_from_flag, add_to_flag){
    // isAll => 1:all,0:selected
    // isSorted => 1:sorted,0:unsorted
    var from_box = document.getElementById(from_box_id);
    var to_box = document.getElementById(to_box_id);

    var is_assigning = from_box_id.include('available_');
    
    var i, j;

    if (is_assigning) {
        for(i = 0; i < from_box.options.length; i++) {
            if (isAll != 0 || (from_box.options[i].selected && from_box.options[i].value != "")) {
                from_box.options[i].selected = false;

                var selected_option = from_box.options[i].cloneNode(true);
                if (remove_from_flag != 0) {
                    if (from_box.options[i].style.display == 'none') continue;
                    from_box.options[i].style.display = 'none';
                    from_box.options[i].style.backgroundColor = 'gray';
                }
                
                var selected_option_text = (Prototype.Browser.IE) ? selected_option.innerText : selected_option.text;
                if (isSorted != 0) {
                    for (j = to_box.options.length-1; j >= 0; j--) {

                        var option_text = (Prototype.Browser.IE) ? to_box.options[j].innerText : to_box.options[j].text;
                        if (option_text > selected_option_text) {
                            if (to_box.options.length == (j+1)) to_box.options[j+1] = new Option("","-1");
                            
                            to_box.options[j+1].innerHTML = option_text;
                            to_box.options[j+1].value = to_box.options[j].value;
                        }
                        else {
                            break;
                        }
                    }

                    to_box.options[j+1] = new Option("","-1");
                    to_box.options[j+1].innerHTML = selected_option_text;
                    to_box.options[j+1].value = selected_option.value;
                }
                else {
                    to_box.options[to_box.options.length] = new Option(selected_option_text,selected_option.value);
                }
                
            }
        }
    }
    else {
        for(i = from_box.options.length - 1; i >= 0; i--) {
            if (isAll != 0 || (from_box.options[i].selected && from_box.options[i].value != "")) {
                from_box.options[i].selected = false;
                
                var selected_value = from_box.options[i].value;
                from_box.remove(i);

                if (remove_from_flag != 0) {
                    for (j = 0; j < to_box.options.length; j++) {
                        if (to_box.options[j].value == selected_value) {
                            to_box.options[j].style.backgroundColor = '';
                            to_box.options[j].style.display = '';
                        }
                    }
                }
            }
        }
    }
}

//  create by   : S.Jitta
//  create when : 16/01/2009
//  porpose     : set this to submit button for set property selected in option list
function selectedOption(form) {
    var elements = form.getElementsByTagName("select");
    var element,id_select;
    var i,j;
    for(i = 0; i < elements.length; i++) {
        if (elements[i].id.length > 9 && elements[i].id.substring(0,9) == "available"){
            id_select = elements[i].id.replace("available_","");
            element = document.getElementById(id_select);
            if (!element.multiple) {
                element.multiple = true;
                element.name += "[]";
            }
            for(j=0; j<element.options.length; j++){
                element.options[j].selected = true;
            }
        }
    }
}

function fncClearErr(){
    var main_doc = fncGetMainDocument();
    var div = main_doc.getElementById("error_area");

    if (div != null) {
        div.innerHTML = "";
    }
}

//by ice
function swapHiddenValue(sourceSeq, targetSeq){
    var mySeq = document.getElementById( "sequence_" + sourceSeq );
    var swapSeq = document.getElementById( "sequence_" + targetSeq );

    tmp = mySeq.value;
    mySeq.value = swapSeq.value;
    swapSeq.value = tmp;
}

function swapRowUp(chosenRow){
    if (chosenRow.rowIndex != 0)
    {
        swapHiddenValue(chosenRow.rowIndex +1, chosenRow.rowIndex);
        moveRow(chosenRow, chosenRow.rowIndex-1);
    }
}

function swapRowDown(chosenRow){
    var mainTable = document.getElementById('mainTable');
    
    if (chosenRow.rowIndex != mainTable.rows.length-1)
    {
        swapHiddenValue(chosenRow.rowIndex +1,chosenRow.rowIndex +2);
        moveRow(chosenRow, chosenRow.rowIndex+1);
    }
}

function moveRow(targetRow, newIndex){
    if (newIndex > targetRow.rowIndex)
    {
        newIndex++;
    }
    //establish proper reference to the table
    var mainTable = document.getElementById('mainTable');

    //insert a new row at the new row index
    var theCopiedRow = mainTable.insertRow(newIndex);

    //copy all the cells from the row to move
    //into the new row
    for (var i=0; i<targetRow.cells.length; i++)
    {
        var oldCell = targetRow.cells[i];
        var newCell = document.createElement("td");
        newCell.innerHTML = oldCell.innerHTML;
        theCopiedRow.appendChild(newCell);
        copyChildNodeValues(targetRow.cells[i], newCell);
    }
    //delete the old row
    mainTable.deleteRow(targetRow.rowIndex);
}

function copyChildNodeValues(sourceNode, targetNode){
    for (var i=0; i < sourceNode.childNodes.length; i++)
    {
        try
        {
            targetNode.childNodes[i].value = sourceNode.childNodes[i].value;
        }
        catch(e)
        {

        }
    }
}

//  create by   : S.Jitta
//  create when : 03/02/2009
//  porpose     : this function use in tab_button and tab_page with tab.css
function fncOnCilckTab(tab_id) {
    var tab_table_id = fncFindIdTabTable(tab_id);
    var elementTabTable = document.getElementById(tab_table_id);
    var old_tab_id = elementTabTable.getAttribute("selected_tab");
    elementTabTable.setAttribute("selected_tab", tab_id);
    fncdeSelect_tab(old_tab_id);
    fncSelect_tab(tab_id);
}

function fncdeSelect_tab(tab_id) {

    var objTab = document.getElementById(tab_id);//tab_xxx_9
    objTab.className = objTab.className.replace("_selected","");

    objTab = document.getElementById(tab_id + "_top_left");//tab_xxx_9_top_left
    objTab.className = objTab.className.replace("_selected","");

    objTab = document.getElementById(tab_id + "_top");
    objTab.className = objTab.className.replace("_selected","");

    objTab = document.getElementById(tab_id + "_top_right");
    objTab.className = objTab.className.replace("_selected","");

    objTab = document.getElementById(tab_id + "_content");
    objTab.className = objTab.className.replace("_selected","");

}

function fncSelect_tab(tab_id) {
    var objTab = document.getElementById(tab_id);
    fncAppendClassName(objTab, "_selected");

    tab_id = tab_id.replace("_top_id","");

    objTab = document.getElementById(tab_id + "_top_left");
    fncAppendClassName(objTab, "_selected");

    objTab = document.getElementById(tab_id + "_top");
    fncAppendClassName(objTab, "_selected");

    objTab = document.getElementById(tab_id + "_top_right");
    fncAppendClassName(objTab, "_selected");

    objTab = document.getElementById(tab_id + "_content");
    fncAppendClassName(objTab, "_selected");

}

function fncFindIdTabTable(tab_id){
    arr = tab_id.split("_");
    return tab_id.replace("_" + arr[arr.length-1], "");
}

function fncCheckRebindObjectEvent(e){
    if (e.getAttribute("RebindObjectEvents")=="true")
    {
        e.setAttribute("RebindObjectEvents","false");
    }
}

function fncTriggerRebindObjectEvents(){
    var main_document = fncGetMainDocument();
    var main_div = main_document.getElementById("main");

    main_div.setAttribute("RebindObjectEvents","true");
}

function fncLoadTempFrame() {
    var tmpFrame = fncGetTempFrame();
    if (tmpFrame!=null) tmpFrame.location.href = "/front_desk/temp_form/0";
}

function fncSetdeleted(row_id) {
    var element = document.getElementById(row_id);
    element.className = "tr_deleted";
    element.onmouseenter = "";
    element.onmouseleave = "";
    element.onclick = "";
}

function fncSetOriginalInnerHtml(node_id) {
    var node = document.getElementById(node_id);
    node.setAttribute("original_inner_html", node.innerHTML);
}

function fncSetResetOriginalInnerHtml(node_id){
    var node = document.getElementById(node_id);
    node.innerHTML = node. getAttribute("original_inner_html");
}

function fncGetTopDocument(){
    var i;
    for (i=0; i<window.parent.frames.length; i++) {
        if (window.parent.frames[i].name == "TopFrame") {
            return window.parent.frames[i].document;
        }
    }

    return null;
}

function fncNew_window(url_target){
    parent.document.getElementById("top_frame").cols="*,200";
    window.open(url_target, "tmp_frame");
}

function fncHide(){
    parent.document.getElementById("top_frame").cols="*,0";
}

function fncShow(){
    parent.document.getElementById("top_frame").cols="*,400";
}

function fncCallImageForm(url){
    fncNew_window(url);
    fncShow();
}

function fncCopyImageAndNameToMain(cf_id, image_name){
    var main_doc = fncGetMainDocument();
    var image_field = main_doc.getElementById("image_" + cf_id);
    var hidden_field = main_doc.getElementById("cells_" + cf_id);
    //Refresh Image
    if (image_field != null)
    {
        image_field.src = "/attachments/" + image_name;
        image_field.alt = image_name;
    }
    //Refresh Text Box
    if (hidden_field != null)
    {
        hidden_field.value = image_name;
    }
    //Close Frame & Refresh
    fncHide();
    fncLoadTempFrame();
}

function fncCancelUploadImage(){
    fncHide();
    fncLoadTempFrame();
}

function fncCheckUserInformation(){
    var user_name = document.getElementById("user_login");
    var password = document.getElementById("user_password");
    var password_confirm = document.getElementById("password_confirmation");
    var form = document.getElementById("userform");

    if (user_name.value.length < 3 || user_name.value.length > 12)
    {
        alert("invalid username");
    }
    else if (password != null)
    {
        if (password.value.length < 5 || password.value.length > 12)
            alert("invalid password");
        else if (password.value != password_confirm.value)
            alert("password not match");
        else
            form.submit();
    }
    else
    {
        form.submit();
    }
}

function fncCopyHtmlToPasswordArea(password__url,password_confirmation_url){
    fncAjaxUpdater("password_area",password__url);
    fncAjaxUpdater("password_confirmation_area",password_confirmation_url);
}

function fncOnOffTextfieldinCheckBox(custom_fields_id,other_id){
    var other_text_fields = document.getElementById("cells_"+custom_fields_id+"_"+other_id);
    var other_text_checkbox = document.getElementById("other_checkbox_"+custom_fields_id);
    if (other_text_checkbox.checked)
        other_text_fields.disabled = false;
    else
        other_text_fields.disabled = true;
}

function fncOnOffTextfieldinRadioBox(custom_fields_id,other_id){
    var other_text_fields = document.getElementById("cells_"+custom_fields_id+"_text");
    var other_text_radio = document.getElementById("cells_"+custom_fields_id+"_label_"+other_id);
    if (other_text_radio.checked)
        other_text_fields.disabled = false;
    else
        other_text_fields.disabled = true;
}

function fncCheckStatusDateTime(cf_id,screen_id){
    var date_from;
    var date_to;
    var radio_bt_set;
    var radio_bt_not_set;
    var cal_from;
    var cal_to;

    if (screen_id == "")
    {
        date_from = document.getElementById("custom_fields_"+cf_id+"_from");
        date_to = document.getElementById("custom_fields_"+cf_id+"_to");
        radio_bt_set = document.getElementById("custom_fields_"+cf_id+"_status_set");
        radio_bt_not_set = document.getElementById("custom_fields_"+cf_id+"_status_not_set");
        cal_from = document.getElementById("calendar_"+cf_id+"_from");
        cal_to = document.getElementById("calendar_"+cf_id+"_to");
    }
    else
    {
        date_from = document.getElementById("custom_fields_"+screen_id+"_"+cf_id+"_from");
        date_to = document.getElementById("custom_fields_"+screen_id+"_"+cf_id+"_to");
        radio_bt_set = document.getElementById("custom_fields_"+screen_id+"_"+cf_id+"_status_set");
        radio_bt_not_set = document.getElementById("custom_fields_"+screen_id+"_"+cf_id+"_status_not_set");
        cal_from = document.getElementById("calendar_"+screen_id+"_"+cf_id+"_from");
        cal_to = document.getElementById("calendar_"+screen_id+"_"+cf_id+"_to");
    }
    if (radio_bt_set.checked)
    {
        date_from.disabled = false;
        date_to.disabled = false;
        cal_from.disabled = false;
        cal_to.disabled = false;
    }
    else if (radio_bt_not_set.checked)
    {
        date_from.disabled = true;
        date_to.disabled = true;
        cal_from.disabled = true;
        cal_to.disabled = true;
    }
}

function fncCheckBoxIssueTracking(custom_fields_id){
    var now = new Date();
    var m = now.getMonth() + 1;
    var d = now.getDate();
    if (m < 10) m = "0" + m;
    if (d < 10) d = "0" + d;
    time = now.getFullYear() + "-" + m + "-" + d;
    var tracking_completed_text_field = document.getElementById("cells_" + custom_fields_id + "_Completed_date");
    var tracking_completed_checkbox = document.getElementById("completed_checkbox_" + custom_fields_id);

    if (tracking_completed_checkbox.checked)
    {
        tracking_completed_text_field.disabled = false;
        if (tracking_completed_text_field.value == "")
        {
            tracking_completed_text_field.value = time;
        }
    }
    else
    {
        tracking_completed_text_field.disabled = true;
    }
}

function fncCheckDueDateTracking(custom_fields_id,original_date){
    var due_text_fields = document.getElementById("cells_"+custom_fields_id+"_Due_date");
    var original_hidden_field = document.getElementById("cells_"+custom_fields_id+"_Original_date");
    var tracking_completed_checkbox = document.getElementById("completed_checkbox_" + custom_fields_id);
    // Copy Due date to Original date
    if (original_date == "")
    {
        original_hidden_field.value = due_text_fields.value;
    }

    // Enable/Disable completed check box
    if (due_text_fields.value == "")
    {
        tracking_completed_checkbox.checked = false;
        tracking_completed_checkbox.disabled = true;
    }
    else
    {
        tracking_completed_checkbox.disabled = false;
    }
}

function checkNumber(event, isFloat, isMinus, separator, delimiter){
    var key;
    if(window.event)              //Support IE
        key = window.event.keyCode;
    else if(e)                    //Support Firefox
        key = event.which;
    else                          //Not Support - can key any key.
        return true;

    var keychar = String.fromCharCode(key);

    if((key >= 48 && key <= 57) || (keychar == delimiter))
        return true;
    else if((key==null)||(key==0)||(key==8)||(key==9)||(key==13)||(key==27))
        return true;
    else if((isFloat) && (keychar == separator))
        return true;
    else if((isMinus) && (keychar == "-"))
        return true;
    else
        return false;
}

function fncChkType(val, chk, e){
    var visit_purpose = document.getElementById("cells_" + val);
    if (e.value == chk) // 235 = Visit
    {
        visit_purpose.disabled = false;
    }
    else
    {
        visit_purpose.disabled = true;
        visit_purpose.selectedIndex = -1;
    }
}

function fncChkRadioType(val, chk, e){
    var task = document.getElementsByName("cells[" + val + "][label]");
    if (e.value == chk) // 235 = Visit
    {
        task.disabled = false;
    }
    else
    {
        task.disabled = true;
    }
}

function fncLoadGTotalReport(){
    var inv_from = document.getElementById("invoice_from");
    var inv_to = document.getElementById("invoice_to");
    var filter_by = document.getElementById("filter1");
    var filter_item = document.getElementById("filter2");
    var screen_id = document.getElementById("screen_id");
    if (inv_from.value == "" || inv_to.value == "")
    {
        alert("Please input date!");
    }
    else if (filter_by.value == "")
    {
        alert("Please select reprot type!");
    }
    else
    {
        rid = "2";
        switch (filter_by.value)
        {
            case "245": // Nation
                rid = "0";
                break;
            case "215": // Business Type
                rid = "1";
                break;
            case "214":  //Area Custom Field ID
                rid = "4";
                break;
            case "292": // Province Custom Field ID
                rid = "2";
                break;
            case "319": // Industrial Estate Custom Field ID
                rid = "6";
                break;
            case "309": // Potential  Custom Field ID
                rid = "8";
                break;
            case "246": // Product Type Custom Field ID
                rid = "10";
                break;
            case "218": // Sales Office Custom Field ID
                rid = "12";
                break;
            case "bill": // Bill Count
                rid = "13";
                break;
        }
        url = "/reports/gtotal_report/" + screen_id.value + "?rpt_type=" + rid + "&invoice_from=" + inv_from.value + "&invoice_to=" + inv_to.value + "&filter_item=" + filter_item.value;
        fncAjaxUpdater("report_area",url);
    }
}

function fncReloadComboReport(e){
    var area = "filter_by";
    var url = "/reports/get_reference/0?custom_field_id=" + e.value;
    fncAjaxUpdater(area,url);
}

function fncLoadActionReport(){
    var date_from = document.getElementById("date_from");
    var date_to = document.getElementById("date_to");
    var rpt = document.getElementById("rpt");
    var rpt_group = document.getElementsByName("rpt_group");
    var rpt_type = 4;

    for (var i=0; i < rpt_group.length; i++)
    {
        if (rpt_group[i].checked)
        {
            rpt_type = rpt_group[i].value;
        }
    }

    if (date_from.value == "" || date_to.value == "")
    {
        alert("Please input date!");
    }
    else if (rpt.value == "")
    {
        alert("Please select reprot type!");
    }
    else
    {
        //url = "/reports/search_grand_total" + rid + "/" + screen_id.value + "?invoice_from=" + inv_from.value + "&invoice_to=" + inv_to.value;
        url = "/reports/action_daily_report/0?date_from=" + date_from.value + "&date_to=" + date_to.value + "&rpt=" + rpt.value + "&rpt_type=" + rpt_type;
        fncAjaxUpdater("report_area",url);
    }
}

function fncLoadRankHistoryReport(){
    var date_from = document.getElementById("date_from");
    var date_to = document.getElementById("date_to");
    var screen_id = document.getElementById("screen_id");
    if (date_from.value == "" || date_to.value == "")
    {
        alert("Please input date!");
    }
    else
    {
        //url = "/reports/search_grand_total" + rid + "/" + screen_id.value + "?invoice_from=" + inv_from.value + "&invoice_to=" + inv_to.value;
        url = "/reports/rank_history_report/" + screen_id.value + "?date_from=" + date_from.value + "&date_to=" + date_to.value;
        fncAjaxUpdater("report_area",url);
    }
}

function fncLoadCompareActionReport(){
    var rpt_type = document.getElementById("rpt_type");
    var date_from = document.getElementById("date_from");

    if (rpt_type.value == "")
    {
        alert("Please select report!");
    }
    else if (date_from.value == "")
    {
        alert("Please input date!");
    }
    else
    {
        url = "/reports/compare_action_report/0?rpt_type=" + rpt_type.value + "&date_from=" + date_from.value;
        fncAjaxUpdater("report_area",url);
    }
}

function fncReloadActionReport(e){
    var grp = document.getElementById("grp");
    var txt = "";
    if (e.value == "")
    {
        txt = "";
    }
    else if (e.value == "1")
    {
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"1\"> Product Type";
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"2\"> Sales Office";
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"3\"> Salesman";
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"4\" checked> Potential Rank";
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"5\"> Customer";
    }
    else if (e.value == "2")
    {
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"1\"> Product Type";
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"2\"> Sales Office";
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"3\"> Salesman";
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"4\" checked> Type";
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"5\"> Customer";
    }
    else
    {
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"1\" checked> Customer";
        txt += "<input type=\"radio\" name=\"rpt_group\" value=\"2\"> Product Type";
    }
    grp.innerHTML = txt;
}

function fncLoadNewRowScreen(screen_id, cf_id, row_id){
    fncLoadAjaxByScreenId("/rows/new/" + screen_id + "?action_source=relations&filtered_reference%5B" + cf_id + "%5D=" + row_id + "/","/screens/search/" + screen_id);
    fncSetSelectedMenuItem([screen_id]);
}
//var g_AutoTimer_Enambed = false;
function fncAutoTimer(){
    fncAutoTimer(true);
    fncMonitorTempFrame();
}
    
function fncAutoTimer(update_time){
    try {
        doAutoExecute(update_time);
    }
    catch (err)  {
        txt="There was an error on this page.\n\n";
        err_message = (err.constructor == String) ? err : err.message;
        txt+="Error message: " + err_message + "\n\n";
        txt+="Click OK to continue.\n\n";
        alert(txt);
    }

    setTimeout ( "fncAutoTimer(true)", 1000 );
}

var _temp_frame_timer = 0;
function fncMonitorTempFrame(){
    if (_temp_frame_timer > 0)
    {
        clearTimeout(_temp_frame_timer);
    }

    var tmp_document = fncGetTempDocument();

    if (tmp_document.body != null) 
    {
        var production_error = RegExp("We're sorry, but something went wrong").test(tmp_document.body.innerHTML);
        var devlopment_error = RegExp("RAILS_ROOT").test(tmp_document.body.innerHTML);

        if (production_error) {
            alert("We're sorry, but something went wrong.\nWe've been notified about this issue and we'll take a look at it shortly.");
            fncLoadTempFrame();

            var main_document = fncGetMainDocument();
            main_document.location.href = '/front_desk/welcome';
        }
        else {
            if (devlopment_error) {
                fncShow();
            }
            _temp_frame_timer = setTimeout( "fncMonitorTempFrame()", 4000 );
        }
    }
}

function doAutoExecute(update_time){
    // Add function that you want to automatically call.
    if (update_time) fncUpdateTime();
    fncOnLoadAfterAjaxUpdater();
    fncSetObjectEvent();
}

function fncUpdateTime(){
    var div = document.getElementById("system_time");
    var dt = new Date();
    var datetime = dt.toString();
    var separator_pos = datetime.indexOf(" GMT");

    if (separator_pos < 0 ) separator_pos = datetime.indexOf(" UTC");

    div.innerHTML = datetime.substr(0, separator_pos);
}

function fncClearSelectOption(select_opt_ids, opt_left) {
    var no = null;
    for (i=0; i<select_opt_ids.length; i++){
        td = document.getElementById(select_opt_ids[i]);
        if (td != null && td.children.length > 0){
            opt = td.children[0];
            if (opt.options.length > 1) {
                no = new Option();
                no.value = opt.options[0].value;
                no.text = opt.options[0].text;
                opt.length = 0;
                opt[0] = no;
            }
        }
    }
}

function fncClearTextBox(select_opt_ids){
    for (i=0; i<select_opt_ids.length; i++){
        textbox = document.getElementById(select_opt_ids[i]);
        textbox.value = "";
    }
}

function fncClearContent(select_opt_ids){
    for (i=0; i<select_opt_ids.length; i++){
        content = document.getElementById(select_opt_ids[i]);
        content.innerHTML = "";
    }
}

function fncToggleRelationArea(div_id, checkbox){
    var div = document.getElementById(div_id);
    div.style.display = (checkbox.checked) ? "block" : "none";

    createCookie("auto_load_relation_content", checkbox.checked, 24*7);
}

function fncSetDate(date_format_name, field_month_id, field_year_id, hidden_tag_id, start_period, null_date){
    var hidden_tag = document.getElementById(hidden_tag_id);
    var year = document.getElementById(field_year_id).value;
    null_date = Date.CDate(null_date);
    
    if (year == 0)
        {dt_value = null_date;}
    else
    {
            var business_start_date = new Date(year,null_date.getMonth(),null_date.getDate());
            var dt_value = business_start_date;
            var code = "yyyy";
            
            if (date_format_name != "year"){
                    var value = document.getElementById(field_month_id).value;
                    if (value != 0){
                        switch (date_format_name){
                            case "quarter_year":
                                code = "q";
                                dt_value = Date.DateAdd(code, value-1, business_start_date);
                                break;
                            case "half_year":
                                code = "ha";
                                dt_value = Date.DateAdd(code, value-1, business_start_date);
                                break;
                            default:
                                code = "m";
                                dt_value = new Date(year,value-1,1);
                        }
                    }
            }
        if (!(start_period)) {dt_value = Date.DateAdd("w", -1, (Date.DateAdd(code, 1, dt_value)));}
    }
    hidden_tag.value = dt_value;
}

function fncReCalculateCCRAttributeValue(ccrAttributeId, value, checked) {
    var txtBox = document.getElementById(ccrAttributeId) ;
    if (txtBox != null) {
        txtBox.value = txtBox.value.trim();
        if (txtBox.value == "") txtBox.value = 0.0;
        
        var original_value = parseFloat(txtBox.value) ;
        var new_value = original_value + (checked ? 1 : -1) * value;
        if(new_value < 0){new_value = 0 ;}
        txtBox.value = new_value ;
    }
}

function fncSetDisplayOptions(h_options, selected_option, field_option_name){
    var tr_elements = document.getElementsByTagName("tr");
    var options = h_options[selected_option];

    for(var i = 0; i < tr_elements.length; i++){
        if(RegExp("\^tr_display").test(tr_elements[i].className)){
            var isDisplay = (options.indexOf(tr_elements[i].id) != -1);
            tr_elements[i].className = tr_elements[i].className.replace("_none","");
            tr_elements[i].className += (isDisplay) ? "" : "_none" ;

            var option_field_id = field_option_name + "_" + tr_elements[i].id.replace("tr_","");
            fncSetDisabledField([option_field_id],!isDisplay);
        }
    }
}

function fncSetDisabledField(arr_field_id, isDisabled){
    for(i = 0; i < arr_field_id.length; i++){
        var field = document.getElementById(arr_field_id[i]);
        field.disabled = isDisabled;
    }
}

function onCalSelected(input_id, date_value){
    alert(input_id + ' = ' + date_value);
}

/*Set numeric format that customized by options.
  -is_include_delimiter  set result have delimiter or not.
                         /true/=> result have delimiter (ex. 5,214,56.00) /false/=> result don't have delimiter (ex. 521456.00)
  -is_error_include_blank    when input value with incorrect format.
                            /true/=> Sets value = 'blank' /false/=> Sets value = 0 */
function fncSetNumericFormat(field_value, precision, separator, delimiter, is_include_delimiter, is_error_include_blank) {
    if(delimiter != ""){field_value = field_value.toString().replace(new RegExp("\\" + delimiter, "g"),"");}
    if(separator != ""){field_value = field_value.toString().replace(new RegExp("\\" + separator, "g"),".");}

    field_value = field_value.trim();

    if(is_error_include_blank) {
        if((field_value == "") || (isNaN(field_value))) return "";
    }
    else {
        if(isNaN(field_value)) field_value = "0";
    }

    var sign = (field_value == (field_value = Math.abs(field_value)));
    var expPrecision = Math.pow(10,precision);
    var rounded = Math.round(field_value * expPrecision);
    var sNumber = Math.floor(rounded / expPrecision).toString();
    var sDecimal = (rounded % expPrecision).toString();

    //set decimal rang
    while(sDecimal.length < precision){sDecimal = "0" + sDecimal;}
    if(precision == 0){sDecimal = "";} else {sDecimal = "." + sDecimal;}

    //set delimiter for show
    if(is_include_delimiter){
        for(i = 0; i < Math.floor((sNumber.length-(1+i))/3); i++){
            sNumber = sNumber.substring(0,sNumber.length-(4*i+3)) + delimiter + sNumber.substring(sNumber.length-(4*i+3));
        }
    }
    return (((sign)? '' : '-') + sNumber + sDecimal);
}

function fncSetNumericFormatToSave(form) {
    var elements = null;

    elements = form.getElementsByTagName("div");

    for(i = 0; i < elements.length; i++){
        element = elements[i];
        element_name = (Prototype.Browser.IE) ? element.name : element.getAttribute('name');
        if (element_name == "custom_field_numeric") {
            fncSetNumericValue(element);
        }
    }
}

function fncSetNumericValue(div)
{
    var h_options = {};
    var cell ;

    for(j = 0; j < div.childNodes.length ; j++){
        child = div.childNodes[j]

        if(child.tagName == "INPUT"){
            if(child.type == "hidden")
                h_options[child.id] = child.value;
            else
                cell = child;
        }
    }

    cell.value = fncSetNumericFormat(cell.value, h_options["precision"], h_options["separator"], h_options["delimiter"], false, false);
}

function fncCheckKeyInput(event, isNumeric, isLowerChar, isUpperChar, arr_symbol, isNonEnglish){
    var key;
    if(window.event)                //Support IE
        key = window.event.keyCode;
    else if(e)                      //Support Firefox
        key = event.which;
    else                            //Not Support - can key any key.
        return true;

    /* Control Keys */
    if((key==null)||(key==0)||(key==8)||(key==9)||(key==13)||(key==27)||(key==32))
        return true;

    var keychar = String.fromCharCode(key);
    var key_RegExp;
    key_RegExp = isNumeric ? "\[0-9]" : "" ;  
    key_RegExp += (isLowerChar||isUpperChar) ? ((key_RegExp.length > 0) ? "|" : "") + "\[A-z]" : "" ;
    key_RegExp += (arr_symbol.length > 0) ? ((key_RegExp.length > 0) ? "|" : "") + "\\" + arr_symbol.join("|\\") : "" ;
    key_RegExp += isNonEnglish ? ((key_RegExp.length > 0) ? "|" : "") + "\[^\\u0000-\\u007F]" : "" ;

    
    return RegExp(key_RegExp).test(keychar);
}

function fncUpdateParameterField(arr_param_updater, update_value){
    for(i = 0 ; i < arr_param_updater.length ; i++){
        var params = arr_param_updater[i];
        fncAjaxUpdaterWithReplacement(params["area"], params["url"], [params["replacment_var"], update_value]);
    }
}

function fncChangeClass(div_id, fromClass, toClass){
    var main_doc = fncGetMainDocument();
    var area = main_doc.getElementById(div_id);
    area.className = area.className.replace(fromClass, toClass);
}

function fncAlreadySetRadio(radio_id){
    var radio = document.getElementById(radio_id);
    radio.checked = "checked";
}

function fncWriteBrowserInfo() {
    var useragent = navigator.userAgent;
    var bName = (useragent.indexOf('Opera') > -1) ? 'Opera' : navigator.appName;
    var pos = useragent.indexOf('MSIE');
    var bVer;
    if (pos > -1) {
        bVer = useragent.substring(pos + 5);
        pos = bVer.indexOf(';');
        bVer = bVer.substring(0,pos);
    }
    pos = useragent.indexOf('Opera');
    if (pos > -1)	{
        bVer = useragent.substring(pos + 6);
        pos = bVer.indexOf(' ');
        bVer = bVer.substring(0, pos);
    }
    if (bName == "Netscape") {
        bVer = useragent.substring(8);
        pos = bVer.indexOf(' ');
        bVer = bVer.substring(0, pos);
    }
    if (bName == "Netscape" && parseInt(navigator.appVersion) >= 5) {
        pos = useragent.lastIndexOf('/');
        bVer = useragent.substring(pos + 1);
    }
    if (bName == "Netscape"&& useragent.indexOf('Firefox') > -1) {
        bName = 'Firefox';
    }
    document.writeln(bName + ' v.' + bVer);
}

function set_state_option_tag(input, selected_name){
    var td = input.parentNode;
    var tr = td.parentNode;
    var select_inputs = tr.getElementsByTagName("select");

    for(var i = 0; i < select_inputs.length; i++){
        select_input = select_inputs[i];
        if (select_input.id.include("row_id") &&
                select_input.parentNode.id != "" &&
                select_input.id.include(select_input.parentNode.id)) {
            display = select_input.id.replace(select_input.parentNode.id + "_", "") == input.value;
            select_input.style.display = selected_name == 'group' ? "" : "none";

        }
    }
}

function fncZeroPad(num,count)
{
    var numZeropad = num + '';

    while(numZeropad.length < count)
    {
        numZeropad = "0" + numZeropad;
    }

    return numZeropad;
}

function fncSetDateTimeFormat(input, format_value, value)
{
    var date = Date.Format(new Date(value.replace(new RegExp("-", "g"),"/")), format_value.toLowerCase().replace('%d','dd').replace('%m','mm').replace('%y','yyyy'));

    var input_id = document.getElementById(input);
    input_id.value = date;
}

function ResetDateTimeRange(date_format_name, hidden_tag_id, date_time_range_year_to_id, null_date){
    var date_time_range_month_to_id = date_time_range_year_to_id.replace("year", "month");
    null_date = new Date(null_date);

    var date_time_range_year_to = document.getElementById(date_time_range_year_to_id);
    var date_time_range_month_to = document.getElementById(date_time_range_month_to_id);
    var date_time_range_year_from = document.getElementById(date_time_range_year_to_id.replace("to", "from"));
    var date_time_range_month_from = document.getElementById(date_time_range_month_to_id.replace("to", "from"));
    
    date_time_range_year_to.options[date_time_range_year_to.selectedIndex].selected = false;
    date_time_range_year_from.options[date_time_range_year_from.selectedIndex].selected = false;    
    
    if (date_time_range_month_from != null && date_time_range_month_to != null){
        date_time_range_month_to.options[date_time_range_month_to.selectedIndex].selected = false;
        date_time_range_month_from.options[date_time_range_month_from.selectedIndex].selected = false;
    }

    fncSetDate(date_format_name, date_time_range_month_to_id, date_time_range_year_to_id, hidden_tag_id, true, null_date);
    fncSetDate(date_format_name, date_time_range_month_to_id.replace("to", "from"), date_time_range_year_to_id.replace("to", "from"), hidden_tag_id.replace("to", "from"), true, null_date);
}

function fncAppendClassName(obj, postfix)
{
    obj.className = obj.className.replace(postfix, "") + postfix
}

function fncCalendarNavigate(date_from, date_to, calendar_view, custom_field_id, screen_id) {
    $('custom_fields_'+ custom_field_id + '_from').value = date_from;
    $('custom_fields_'+ custom_field_id + '_to').value = date_to;
    if (!calendar_view){$('view_mode').value = -1;}

    $('frm_search_' + screen_id).submit();

    fncSubmitSearch();
}

function fncSetCalendarColor(custom_field_id)
{
    var i;
    var divs = document.getElementsByName('calendar_data');
    
    for(i = 0; i < divs.length; i++){
        class_name = divs[i].className
        
        class_name = class_name.replace(" clr_field_", " xxx_");
        class_name = class_name.replace(" xxx_" + custom_field_id, " clr_field_" + custom_field_id);
        
        divs[i].className = class_name;
    }

    divs = document.getElementsByName('calendar_legend');
    
    for(i = 0; i < divs.length; i++){
        divs[i].style.display = 'none';
    }

    if ($('calendar_legend_' + custom_field_id) != null) $('calendar_legend_' + custom_field_id).style.display = '';
}

function fncResetSelectSearch(){
    var select_elements = document.getElementsByTagName("input");
    for(i=0; i< select_elements.length; i++){
        if (select_elements[i].type == "hidden") {
            select_elements[i].value = "";
        }
    }
}