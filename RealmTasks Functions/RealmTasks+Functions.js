var Wit = require("node-wit").Wit;
var WIT_ACCESS_TOKEN = "";
var witClient = new Wit({accessToken: WIT_ACCESS_TOKEN});

module.exports = function(change_event) {
    var realm = change_event.realm;
    var changes = change_event.changes.Task;
    var taskIndexes = changes.modifications;
    console.log("Change detected: " + changes);
    // Get the task objects to processes
    var tasks = realm.objects("Task");
    for (var i = 0; i < taskIndexes.length; i++) {
        var taskIndex = taskIndexes[i];
        // Retrieve the task object from the Realm with index
        var task = tasks[taskIndex];
        console.log("New task received: " + change_event.path);
        // get date from wit.ai
        // probably use this https://wit.ai/docs/http/20160526#get--message-link
        // node-wit: https://github.com/wit-ai/node-wit
        witClient.message(task.text, {}).then((data) => {
            console.log("Response received from wit: " + JSON.stringify(data));
            var dateTime = data.entities.datetime[0];
            if (!dateTime) {
                console.log("Couldn't find a date.");
                return;
            }
            console.log("Isolated calculated date: " + dateTime.value);
            // to write the date, we'll have to add a date property on the client and migrate it
            realm.write(function() {
                task.date = new Date(dateTime.value);
            });
        })
        .catch(console.error);
    }
};