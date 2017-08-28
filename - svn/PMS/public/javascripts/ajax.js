var g_alAjaxUpdaters = new Array();
var n_activeUpdaters = 0;

function fncAjaxUpdater(strDivId, strUrl)
{
    fncAjaxUpdater(strDivId, strUrl, false);
}

function fncAjaxUpdater(strDivId, strUrl, display_progress)
{
    var main_doc = fncGetMainDocument(); 
    var div = main_doc.getElementById(strDivId);

    if (div == null) return;

    div.setAttribute("ajax_updater_state", "loading");
    main_doc.body.style.cursor = 'wait';

    var ajax_updater = new Ajax.Updater(strDivId, strUrl, {
        method:     'get',
        onLoading: function(transport) {
            onAjaxLoading(transport, strDivId);
            
            if (display_progress == true) {
                if (n_activeUpdaters == 0) {
                    fncShowDialog(null, 'pop_box', "<img src='/images/progress.gif' />");
                }
                n_activeUpdaters++;
            }
        },
        onComplete: function(transport) {
            onAjaxComplete(transport, strDivId);
            n_activeUpdaters--;
            if (n_activeUpdaters <= 0 ) {
                n_activeUpdaters = 0;
                fncHideDialog('pop_box');
            }
        },
        onFailure:  function(transport) {
            fncSetElementInnerHtml(strDivId,"<span class='error_message' href='" + strUrl + "'>Unable to load content</span><div id='error_detail_" + strDivId + "' style='display: none'></div>");
            fncSetElementInnerHtml("error_detail_" + strDivId, transport.responseText);
            n_activeUpdaters--;
            if (n_activeUpdaters <= 0 ) {
                n_activeUpdaters = 0;
                fncHideDialog('pop_box');
            }
        }
    });
    
    g_alAjaxUpdaters.push(ajax_updater);
}

function fncAjaxUpdaterWithReplacement(area, url, replacements)
{
    // Reloading combo box
    for (var i = 0; i < replacements.length; i+=2) {
        url = url.replace(replacements[i], replacements[i+1]);
    }
    fncAjaxUpdater(area, url, true);
}

//  porpose     : load coontent
function onAjaxLoading(transport, resultID)
{
    var main_doc = fncGetMainDocument();
    var div = main_doc.getElementById(resultID);

    if (div == null) return;
    
    if(div.getAttribute("ajax_updater_state") != "loading") {
        return;
    }

    if(resultID == "left_panel_tab_filter_content"){
        fncSetElementInnerHtml(resultID, "<img src='/images/search_loading.gif'>&nbsp;Loading... ");
    }
    else{
        if(resultID.indexOf("operation_area_")>=0){
            fncScrollIntoView(resultID);
        }
        fncSetElementInnerHtml(resultID, "<img src='/images/loading.gif'>&nbsp;Loading... ");
    }
}

function onAjaxComplete(transport, resultID)
{
    var main_doc = fncGetMainDocument();
    var div = main_doc.getElementById(resultID);
    div.setAttribute("ajax_updater_state", "complete");

    if(resultID.indexOf("operation_area_")>=0){
        fncSetOriginalInnerHtml(resultID);
    }
    fncScrollIntoView(resultID);
    main_doc.body.style.cursor = 'auto';
}
function fncAjaxAbort()
{
    while (g_alAjaxUpdaters.length > 0) {
        objAjaxUpdater = g_alAjaxUpdaters.pop();

        objAjaxUpdater.transport.abort();
    }
    
    n_activeUpdaters = 0;
    fncHideDialog('pop_box');
}

function fncSetElementInnerHtml(resultID, strHtml)
{
    var main_doc = fncGetMainDocument();
    div = main_doc.getElementById(resultID);
    if (div != null) {div.innerHTML = strHtml;}
    main_doc.body.style.cursor = 'auto';
}

function fncModelLookUp(div_id, strUrl, fieldIds, customFieldIds)
{
    var arrfieldId, arrCustomFieldId;
    arrfieldId = fieldIds.split(",");
    arrCustomFieldId = customFieldIds.split(",");
    var fieldVal;
    var complete = new Boolean();
    complete = true;

    for (var i = 0; i < arrfieldId.length; i++){
        
        fieldVal = document.getElementById('flag_field_' + arrfieldId[i]).value;
        if (fieldVal == ''){
            complete = false;
            return 0 ;
        }
        strUrl += "&cf_id[" + arrCustomFieldId[i] + "]" + "=" + fieldVal;
    }

    strUrl += "&div_id=" + div_id

    if (complete) {
        fncSetOperationContent(div_id, strUrl, 'request');
    }
}