// support the Harvard-style search block

function new_row_from_template() {
    var num = $as.find(".search_row").size();
    var $row = $template.clone();
    replace_id_ref($row, 'label', 'for', num);
    replace_id_ref($row, 'input', 'id', num);
    replace_id_ref($row, 'select', 'id', num);
    $row.attr("id", "search_row_" + num);
    $row.find("input[type=submit]").remove();
    new_button($row, true);
    $row.keypress(submit_on_enter);
    return $row;
}
