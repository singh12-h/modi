importScripts('https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/sql-wasm.js');

onmessage = function(e) {
  var data = e.data;
  var db = data.db;
  var sql = data.sql;
  var params = data.params;
  try {
    var result = db.exec(sql, params);
    postMessage({result: result});
  } catch (err) {
    postMessage({error: err.message});
  }
};
