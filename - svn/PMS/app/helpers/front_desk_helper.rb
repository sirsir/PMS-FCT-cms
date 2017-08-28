module FrontDeskHelper

# ============================================
# create by     : S.Jitta  
# create when   : 25/12/2008
# porpose       : create function bind_object_events
# ============================================

  def bind_object_events
    <<JAVASCRIPT
<script type="text/javascript">
  fncAutoTimer();
  fncMonitorTempFrame();
  if (readCookie('left_panel')=='none') {
    fncToggleLeftPanel();
  }
  if (readCookie('left_panel_tab_filter_content')=='none') {
    fncToggleSearchPanel();
  }
</script>
JAVASCRIPT
  
  end
 

 


end
