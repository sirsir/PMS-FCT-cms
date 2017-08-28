function fncAjaxUpdater_ReplaceTR(strDivId, strUrl)
{
    var ajax_updater = new Ajax.Updater(strDivId, strUrl, {
        method:     'get',
        onLoading: function(transport) {},
        onComplete: function(transport) {
            onAjaxComplete_MoveTR(transport, strDivId);
        },
        onFailure:  function(transport) {
            fncSetElementInnerHtml_LoadingTD(strDivId,"<span class='error_message' href='" + strUrl + "'>Unable to load record</span><div id='error_detail_" + strDivId + "' style='display: none'></div>");
            fncSetElementInnerHtml("error_detail_" + strDivId, transport.responseText);
        }
    });

    g_alAjaxUpdaters.push(ajax_updater);
}

function onAjaxComplete_MoveTR(transport, resultID)
{
    var div = document.getElementById(resultID);
    var tmp_table = null;
    for (i = 0; i < div.childNodes.length; i++) {
        tmp_table = div.childNodes[i];
        if (tmp_table.tagName == 'TABLE') break;
    }
    var tr_ = tmp_table.rows[0];

    var row_id = tr_.id.replace("_replacement", "");

    var tr =  document.getElementById(row_id);
    var tbody = tr.parentNode;
    tbody.insertBefore(tr_, tr);
    tbody.removeChild(tr);

    fncCopyAttributes(tr, tr_);

    div.parentNode.removeChild(div);
}

function fncCopyAttributes(src, dst)
{
    dst.id = src.id;
    dst.className = src.className;
       
    var attr = ["pre_ajax_result_id", "pre_ajax_url",
        "operation_url", "operation_area",
        "relation_url", "relation_area",
        "post_ajax_result_id", "post_ajax_url",
        "handleonclick"];
    for (var i = 0; i < attr.length; i++) {
        dst.setAttribute(attr[i], src.getAttribute(attr[i]));
    }

    fncSetTrEvent(dst);
}

function fncSetElementInnerHtml_LoadingTD(resultID, strHtml)
{
    var div = document.getElementById(resultID);
    var td = document.getElementById(div.getAttribute("cell_id"));
    td.innerHTML = strHtml;
}

function fncAppendTrToTableContent(screen_id, row_id)
{
    var main_doc = fncGetMainDocument();
    var table = main_doc.getElementById("table_content_" + screen_id);

    if (table == null) return;

    if (table != null){
        var tbody = table.getElementsByTagName("TBODY")[0];
        var empty_loading_row = main_doc.getElementById("" + screen_id + "_empty_loading_row");
        var tr_ = empty_loading_row.cloneNode(true);

        tbody.appendChild(tr_);

        fncSetRowAttribute(tr_, row_id, "new", screen_id);
    }
}

function fncUpdateTrToTableContent(screen_id, row_id)
{
    var main_doc = fncGetMainDocument();
    var table = main_doc.getElementById("table_content_" + screen_id);

    if (table == null) return;

    var tr = main_doc.getElementById(row_id);

    var tbody = table.getElementsByTagName("TBODY")[0];
    var empty_loading_row = main_doc.getElementById("" + screen_id + "_empty_loading_row");
    var tr_ = empty_loading_row.cloneNode(true);

    tbody.insertBefore(tr_, tr);
    tbody.removeChild(tr);

    fncSetRowAttribute(tr_, row_id, "edit", screen_id);
}

function fncDeleteSelected(screen_id)
{
    var chk_screen = "select_" + screen_id.toString();

    var all_id = "select_"+ screen_id + "_all";
    var all = document.getElementById(all_id);
    var params = [];

    $$('input').each(
        function(e){
            if(e.type == 'checkbox') {
                if ((e.id.toString().substr(0, chk_screen.length) == chk_screen) && (e != all) ) {
                    if(e.checked == true){
                        row_id = e.id.replace(chk_screen + "_", "");
                        
                        var tr = document.getElementById(row_id);
                        tr.setAttribute("handleonclick", "false");
                        tr.click();

                        params = params.concat(["row_ids[]=" + row_id]);
                    }
                }
            }
        }
    );
    
    if (params.length > 0 && confirm('Are you sure?')) {
        params = params.concat(['screen_id=' + screen_id]);

        var tmp_document = fncGetTempDocument();
        var tmp_frm = tmp_document.getElementById("tmp_form_id");

        if (tmp_frm == null)  {
            alert("Application not ready. Please try again later.");

            return;
        }

        fncShowDialog(null, "pop_box", "<img src='/images/progress.gif' />");

        all.checked = false;
        fncEnableChkBoxOperarion(screen_id, false);

        // Set Temp Form's attributes'
        tmp_frm.method = 'POST'; //'DELETE';
        tmp_frm.action = '/rows/0?' + params.join('&');

        var inputs = tmp_frm.getElementsByTagName('input');
        for(var i = 0; i < inputs.length; i++) {
            input = inputs[i];
            if (input.name == '_method') {
                // Change the inner method to delete
                input.value = 'delete';
            }
        }

        // Set the enctype to application/x-www-form-urlencoded, to match with POST method
        tmp_frm.enctype = "application/x-www-form-urlencoded";

        tmp_frm.submit();
    }
}
function fncTrDelete(url, row_id)
{
    // Stop the tr from handling the click event
    var tr = document.getElementById(row_id);
    tr.setAttribute("handleonclick", "false");

    var tmp_document = fncGetTempDocument();
    var tmp_frm = tmp_document.getElementById("tmp_form_id");

    if (tmp_frm == null)  {
        alert("Application not ready. Please try again later.");
        
        return;
    }

    fncShowDialog(tr.parentNode, "pop_box", "<img src='/images/progress.gif' />");

    // Set Temp Form's attributes'
    tmp_frm.method = 'POST'; //'DELETE';
    tmp_frm.action = url;
    
    var inputs = tmp_frm.getElementsByTagName('input');
    for(var i = 0; i < inputs.length; i++) {
        input = inputs[i];
        if (input.name == '_method') {
            // Change the inner method to delete
            input.value = 'delete';
        }
    }
    
    // Set the enctype to application/x-www-form-urlencoded, to match with POST method
    tmp_frm.enctype = "application/x-www-form-urlencoded";
    
    tmp_frm.submit();
}


function fncTrShow(url, div_id, row_id)
{
    // Stop the tr from handling the click event
    var tr = document.getElementById(row_id);
    tr.setAttribute("handleonclick", "false");

    fncScrollIntoView(div_id);
    
    fncAjaxUpdater(div_id, url);
}

function fncSetTrDeleted(row_id)
{
    var main_doc = fncGetMainDocument();
    var tr = main_doc.getElementById(row_id);

    tr.className = "tr_deleted";
    tr.onmouseenter = "";
    tr.onmouseleave = "";
    tr.onclick = "";
    
    var td;
    td = main_doc.getElementById(row_id + '_destroy');
    td.innerHTML = "&nbsp;";

    td = main_doc.getElementById(row_id + '_select');
    if (td != null) td.innerHTML = "&nbsp;";
}

function fncSetOperationContent(div_id, url)
{
    fncSetOperationContent(div_id, url, "update") ;
}

function fncSetOperationContent(div_id, url, ajax_call_mode)
{

    var main_doc = fncGetMainDocument();
    var div = main_doc.getElementById(div_id);
    div.innerHTML = "<div name='on_load_operation_content' status='unloaded' ajax_url='" + url + "' ajax_result_id='" + div_id + "' ajax_call_mode='" + ajax_call_mode + "'><img src='/images/loading.gif'>&nbsp;Loading...</div>";
}

function fncSetError(err_msg, area_id)
{
    var div_id = "error_area";
    if (area_id != null) div_id += "_" + area_id;

    var main_doc = fncGetMainDocument();
    var div = main_doc.getElementById(div_id);
    if (div != null){
        div.innerHTML = err_msg;
        div.setAttribute('scroll_in_to_view', true);
        fncScrollIntoView(div_id);

        fncHideDialog("pop_box");
    }
}

function fncToogleReportRequestRows(a)
{
    var arr_child_ids = a.getAttribute("child_report_request_row_ids");
    if (arr_child_ids == null ) {
        arr_child_ids = [];
    }
    else {
        arr_child_ids = arr_child_ids.split(",");
    }
    
    var i;
    var tr_;
    
    if (a.getAttribute("status") == "closed") {
        a.setAttribute("status", "opened");
        a.innerHTML = "-";
    }
    else {
        a.setAttribute("status", "closed");
        a.innerHTML = "+";
    }

    var a_status_closed = a.getAttribute("status") == "closed";

    for (i=0; i<arr_child_ids.length; i++ ) {
        tr_ = document.getElementById("report_request_row_" + arr_child_ids[i]);

        if (a_status_closed) {
            tr_.style.display='none';

            var a_ = document.getElementById("report_request_row_group_button_" + arr_child_ids[i]);
            if (a_ != null && a_.getAttribute("status") != "unloaded") {
                a_.setAttribute("status", "opened");
                fncToogleReportRequestRows(a_);
            }
        }
        else {
            tr_.style.display='';
        }
    }
}

function fncSetReportRequestRows(tr, id)
{
    tr.id = "report_request_row_" + id;

    var i;

    var td = null;
    for (i=0; i < tr.childNodes.length && td==null; i++) {
        if (tr.childNodes[i].tagName == "TD") {
            td = tr.childNodes[i];
            break;
        }
    }
    
    td.id = "td_loading_" + id;

    for (i=0; i < td.childNodes.length; i++) {
        var div = td.childNodes[i];
        if (div.id == "div_empty_loading_row") {
            div.id = "div_" + id;
            div.setAttribute("row_id", id);
            div.setAttribute("cell_id","td_loading_" + id);
            div.setAttribute("ajax_status", "unloaded");
            div.setAttribute("ajax_result_id", div.id);
            div.setAttribute("ajax_url", div.getAttribute("ajax_url").replace("empty_loading_row", id));
            break;
        }
    }
}

function fncSetRowAttribute(tr, id, tr_class, screen_id)
{
    tr.id = id;
    tr.style.display = "";
    tr.className = "tr_" + tr_class;
    tr.setAttribute("operation_url", tr.getAttribute("operation_url").replace("" + screen_id + "_empty_loading_row", id));
    tr.setAttribute("relation_url", tr.getAttribute("relation_url").replace("" + screen_id + "_empty_loading_row", id));

    var i;

    var td = null;
    for (i=0; i < tr.childNodes.length && td==null; i++) {
        if (tr.childNodes[i].tagName == "TD") {
            td = tr.childNodes[i];
        }
    }
    
    td.id = "td_loading_" + id;
    
    for (i=0; i < td.childNodes.length; i++) {
        var div = td.childNodes[i];
        if (div.id == "div_" + screen_id + "_empty_loading_row") {
            div.id = "div_" + id;
            div.setAttribute("row_id", id);
            div.setAttribute("cell_id","td_loading_" + id);
            div.setAttribute("ajax_status", "unloaded");
            div.setAttribute("ajax_result_id", div.id);
            div.setAttribute("ajax_url", div.getAttribute("ajax_url").replace("" + screen_id + "_empty_loading_row", id));
            break;
        }
    }
}

function fncSetReportRequestRowStateLevel(table_id, report_request_row_state_level)
{
    report_request_row_state_level = parseInt(report_request_row_state_level);
    table = $(table_id)
    var i, j;
    for (i = 0; i < table.rows.length; i++) {
        var tr_ = table.rows[i];
        tr_report_request_row_state_level = tr_.getAttribute("report_request_row_state_level");
        
        if (tr_report_request_row_state_level != null) {
            tr_.style.display = (parseInt(tr_report_request_row_state_level) <= report_request_row_state_level) ? '' : 'none';

            var a_ = document.getElementById("report_request_row_group_button_" + tr_.id.replace('report_request_row_',''));

            if (a_ != null) {
                var prending_loading = a_.getAttribute("status") == "unloaded"

                status = (parseInt(tr_report_request_row_state_level) < report_request_row_state_level) ? "opened" : "closed"
                a_.setAttribute("status", status);
                
                if (a_.getAttribute("status") == "opened") {
                    a_.innerHTML = "-";
                }
                else {
                    a_.innerHTML = "+";
                }
                
                if (prending_loading) {
                    a_.setAttribute("status", "unloaded");
                }
            }
        }
            
    }
    
}

function fncToggleTr(tr){
    if (tr.style.display=='' || tr.style.display=='block') {
        tr.style.display='none';
    }
    else {
        tr.style.display='';
    }
}

function fncToggleTrs(show_tr_id, all_tr_ids){
    var i;
    for (i = 0; i < all_tr_ids.length; i++) {
        var tr_ = $(all_tr_ids[i])

        tr_.style.display='none';
        
        $(all_tr_ids[i].replace('_form', '_th')).rowSpan = '1';

    }

    fncToggleTr($(show_tr_id));
    $(show_tr_id.replace('_form', '_th')).rowSpan = '2';
}

function fncSwitchRemark(show_remark_id, hide_remark_id, row_id)
{
    $(hide_remark_id).style.display = "none";
    $(show_remark_id).style.display = "";
    if (row_id != "") $(row_id).setAttribute("handleonclick", "false");
}

function fncChangeStockKey(strUrl, inputs)
{
    var cnt = 2;
    var i, j;

    for (i = 0; i < inputs.length; i++)
    {
        var javascript_value = "JAVASCRIPT_VAR_VALUE_" + fncZeroPad(i,cnt);
        var input_ids = inputs[i];

        for (j = 0; j < input_ids.length; j++)
        {
            var input_id = document.getElementById(input_ids[j]);
            var input_value = "";

            if (input_id.type == "radio")
            {
                if (input_id.checked)
                {
                    input_value = input_id.value;
                }
            }
            else
            {
                input_value = input_id.value;
            }

            if (input_value.length > 0)
            {
                strUrl = strUrl.replace(javascript_value, input_value);
            }
        }
    }

    all_set = !RegExp("JAVASCRIPT_VAR_VALUE_").test(strUrl);

    if (all_set)
    {
        new Ajax.Request(strUrl, {asynchronous:true, evalScripts:true});
    }
}

function fncSetStockValue(key_values, current_value)
{
    var i, j;

    for (i = 0; i < key_values.length; i++)
    {
        j = 0;
        var input_values = key_values[i];

        var input_id = document.getElementById("stock_item_stock_key_id_"+i);

        alert(input_id);
        alert(input_values[j]);

        input_id.value = input_values[j];

        var span_id = document.getElementById("span_stock_item_stock_key_id_"+i);

        alert(span_id);
        alert(input_values[j+1]);

        span_id.innerHTML = input_values[j+1];
    }

    var current_input_id = document.getElementById("stock_current_value");
    current_input_id.value = current_value;    
}

function fncAddStockTransactionRow(stock_transaction_temp_row_id, stock_transaction_loc) {
    var tbody = document.getElementById(stock_transaction_loc);
    var tr_ = document.getElementById(stock_transaction_temp_row_id);
    var tmp_tr = tr_.cloneNode(true)

    tbody.appendChild(tmp_tr);
}

function fncUpdateCellCalendar(value, td_id, screen_id){
    new Ajax.Updater(td_id, '/rows/update_cell_calendar',
    {
        asynchronous:true,
        parameters: "detail_cell_value= " + value + "&screen_id= " + screen_id
    });
}

function fncSelectAll(all){
    var tr_id = all.id.replace('_all', '');
    $$('input').each(
        function(e){
            if(e.type == 'checkbox') {
                if (e.id.toString().substr(0, tr_id.length) == tr_id) { 
                    e.checked = all.checked;
                }
            }
        }
    );
    
    var row_screen_id = tr_id.replace("select_", "");
    fncEnableChkBoxOperarion(row_screen_id, all.checked);
}

function fncHandle(row_id, row_screen_id){
// Stop the tr from handling the click event
  var tr = document.getElementById(row_id);
  tr.setAttribute("handleonclick", "false");

  var all_id = "select_"+ row_screen_id + "_all";
  var all = document.getElementById(all_id);

  var chk_id = "select_"+ row_screen_id + "_" + row_id;
  var chk = document.getElementById(chk_id);

  var chk_screen = "select_" + row_screen_id.toString() + "_";
  var cnt_checked = 0;
  var cnt_unchecked = 0;
  $$('input').each(
      function(e){
          if(e.type == 'checkbox') {
              if ((e.id.toString().substr(0, chk_screen.length) == chk_screen) && (e != all) ) {
                  e.checked ? cnt_checked++ : cnt_unchecked++;
              }
          }
      }
  );
  all.checked = (cnt_unchecked == 0);
  fncEnableChkBoxOperarion(row_screen_id, cnt_checked > 0);
}

function fncEnableChkBoxOperarion(row_screen_id, enabled){
  var oper = ["delete"];
  var i;
  for (i = 0; i < oper.length; i++) {
    var name = "operation[" + row_screen_id + "][" + oper[i] + "]";
    $$('a').each(
          function(e){
              if (e.name.toString().substr(0, name.length) == name) {
                  e.style.color = (enabled) ? "" : "#BBF";
              }
          }
    );
  }
}

function fncChk(check,related_check_id){
    document.getElementById(related_check_id).checked = check.checked;
}

function fncSelectView(select, related_select_id){
    var related_select = document.getElementById(related_select_id);
    related_select.options[related_select.selectedIndex].selected = false;
    related_select.options[select.selectedIndex].selected = true;
}
