
async function load_label(path, label_id, field) {
    var response = await fetch(path);
    var data = await response.json();            
    var label = document.getElementById(label_id);
    label.innerHTML = data[field];
}


async function load_select(path, select_id) {
    var response = await fetch(path);
    var data = await response.json();
    var select = document.getElementById(select_id);
    select.innerHTML = '<option value=""></option>';

    data.forEach(item => {
        var option = document.createElement("option");
        option.value = item;
        option.text = item;
        select.appendChild(option);
    });
}