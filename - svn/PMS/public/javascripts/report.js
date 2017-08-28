function fncAddReportField(field_report_tempate_id, fields_reports_loc, element_name) {
    var fields_reports_div_id = "selected_" + fields_reports_loc + "_fields";
    var tmp_div = document.getElementById(field_report_tempate_id);
    var tmp_location_input = document.getElementById(field_report_tempate_id + "_location");

    tmp_location_input.id = "";
    tmp_location_input.value = fields_reports_loc;
    
    var field_report = tmp_div.cloneNode(true);

    var tbody = document.getElementById(fields_reports_div_id);

    tbody.appendChild(field_report);

    tmp_location_input.id = field_report_tempate_id + "_location";

    var select_tag = field_report.getElementsByTagName("SELECT");

    var i = 0;
    for(i; i < select_tag.length; i++ ){
        if (select_tag[i].name == element_name){
            var j=0;
            if (fields_reports_loc == "col"){
                for (j = select_tag[i].length - 1; j>=0; j--) {
                    var opt = select_tag[i].options[j].value
                    if (opt != "non") {
                        select_tag[i].remove(j);
                    }
                }
                select_tag[i].options[select_tag[i].options.length] = new Option('Auto', 'auto');
            }
        }
    }

    fncReorderTrDataClass(tbody);
}

function fncRemoveReportField(a)
{
    var td = a.parentNode;
    var tr = td.parentNode;
    var tbody = tr.parentNode;
    tbody.removeChild(tr);

    fncReorderTrDataClass(tbody);
}

function fncMmoveReportField(a, move_up)
{
    var td = a.parentNode;
    var tr = td.parentNode;
    var tbody = tr.parentNode;

    var tr_;

    i = tr.rowIndex;
    
    if (move_up && i > 1) {
        tr_ = tbody.rows[i-1];
        tbody.insertBefore(tr, tr_);
    }
    else if (!move_up && i < (tbody.rows.length - 1)) {
        tr_ = tbody.rows[i+1];
        tbody.insertBefore(tr_, tr);
    }

    fncReorderTrDataClass(tbody);
}

function fncReorderTrDataClass(tbody)
{
    for (i = 0; i < tbody.rows.length; i++) {
        var tr = tbody.rows[i];

        if (tr.className == null || tr.className == "tr_header") continue;

        tr.className = "tr_data_" + (((i % 2) != 0) ? "odd" : "even");
    }
}

function fncAddReportCriteria(tr)
{
    if (tr.getAttribute("criteria_status") == "used" ) return;
    
    var tbody = tr.parentNode;
    var tr_ = tr.cloneNode(true);

    tbody.appendChild(tr_);

    tr.setAttribute("criteria_status", "used");
}

function fncSetReportCriteriaFields(input)
{
    var td = input.parentNode;
    var tr = td.parentNode;
    var select_inputs = tr.getElementsByTagName("select");

    for(var i = 0; i < select_inputs.length; i++){
        select_input = select_inputs[i];
        if (select_input.id.include("field_ids") && 
                select_input.parentNode.id != "" && 
                select_input.parentNode.id.charAt(0) == td.id.charAt(0) &&
                select_input.id.include(select_input.parentNode.id)) {
            display = select_input.id.replace(select_input.parentNode.id + "_", "") == input.value;
            select_input.disabled = display ? "" : "disabled";
            select_input.style.display = display ? "" : "none";
        }
    }
    var text_inputs = tr.getElementsByTagName("input")

    for(var j = 0; j < text_inputs.length; j++){
        text_input = text_inputs[j];
        if (text_input.id.include("field_ids") &&
                text_input.parentNode.id != "" &&
                text_input.parentNode.id.charAt(0) == td.id.charAt(0) &&
                text_input.id.include(text_input.parentNode.id)
            ) {
            display = text_input.id.replace(text_input.parentNode.id + "_", "") == input.value;
            text_input.disabled = display ? "" : "disabled";
            text_input.style.display = display ? "" : "none";
        }
    }
}

function fncReloadReportResult(div)
{
    var main_doc = fncGetMainDocument();
    var report_div = main_doc.getElementById(div);

    fncAjaxAbort();
    
    report_div.setAttribute('status', 'unloaded');
}

function fncSetFormulaValue(src_id, dest_id)
{
    var div = document.getElementById(src_id + "_text");
    var td = document.getElementById("td_" + dest_id);
    td.innerHTML = div.innerHTML;

    var hidden= document.getElementById(src_id + "_yaml");
    var hidden_result = document.getElementById(dest_id + "_field_formula");
    hidden_result.value = hidden.value;
}