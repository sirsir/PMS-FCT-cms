function fncChartZoom(current_zoom_id, div_id01, div_id02, max_value_id, area, url, replacements, mode)
{
    var current_zoom = document.getElementById(current_zoom_id);
    var max_value = document.getElementById(max_value_id);
    var main_doc = fncGetMainDocument();
    var div01 = main_doc.getElementById(div_id01);
    var div02 = main_doc.getElementById(div_id02);
    if (max_value.value == null){
        max_value.value = 0;
    }
    if( mode == "IN"){
        if (current_zoom.value >= 175){
            div02.className = div02.className.replace("display", "hide");
        }else if(current_zoom.value == 50){
            div01.className = div01.className.replace("hide", "display");
        }
        current_zoom.value = parseFloat(current_zoom.value) + 25;
    }else if(mode == "OUT"){
        if (current_zoom.value <= 75){
            div01.className = div01.className.replace("display", "hide");
        }
        else if(current_zoom.value == 200){
            div02.className = div02.className.replace("hide", "display");
        }
        current_zoom.value = parseFloat(current_zoom.value) - 25;
    }
    else{
        if(parseInt(mode) == 50){
            div01.className = div01.className.replace("display", "hide");
            div02.className = div02.className.replace("hide", "display");
        }else if(parseInt(mode) == 200){
            div02.className = div02.className.replace("display", "hide");
            div01.className = div01.className.replace("hide", "display");
        }else{
            div01.className = div01.className.replace("hide", "display");
            div02.className = div02.className.replace("hide", "display");
        }
        current_zoom.value = parseFloat(mode);
    }
    url = url.replace(replacements[0], current_zoom.value);
    url = url.replace(replacements[1], max_value.value);
    fncAjaxUpdater(area, url);
}

