import ballerina/sql;
import ballerina/mysql;
import ballerina/log;
import ballerina/http;
import ballerina/config;
import ballerina/io;
import ballerina/system;
import ballerina/internal;

type Medicine{
    string medName;
    int medID;
    int medQuantity;
    string medProvider;
};


// Create SQL endpoint to MySQL database
endpoint mysql:Client medicineDB {
    host: config:getAsString("DATABASE_HOST", default = "localhost"),
    port: config:getAsInt("DATABASE_PORT", default = 3306),
    name: config:getAsString("DATABASE_NAME", default = "medicine_Data"),
    username: config:getAsString("DATABASE_USERNAME", default = "root"),
    password: config:getAsString("DATABASE_PASSWORD", default = ""),
    dbOptions: { useSSL: false }
};

endpoint http:Listener listener {
    port: 9090
};


// Service for the employee data service
@http:ServiceConfig {
    basePath: "/records"
}
service<http:Service> EmployeeData bind listener {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/medicine/{medProvider}"
    }
    retrieveMedicalResources(endpoint httpConnection, http:Request request, string
    medProvider) {
        // Initialize an empty http response message
        http:Response response;
        // Convert the employeeId string to integer
        int medProviderID = check <int>medProvider;

        // Invoke retrieveById function to retrieve data from Mymysql database
        var medicalData = retrieveById(medProviderID);






        // Send the response back to the client with the employee data
        response.setJsonPayload(medicalData);


        _ = httpConnection->respond(response);
    }

}

public function retrieveById(int medProviderID) returns (json) {
    json jsonReturnValue;

    //i changed to name.
    //string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = ?";
    //string sqlString = "SELECT Name FROM EMPLOYEES WHERE Age < 30 OR EMployeeID = ?";
    string  sqlString = "SELECT * FROM Medicine WHERE medQuantity < 30 AND medProvider = ?";

    // Retrieve employee data by invoking select action defined in ballerina sql client
    var ret = medicineDB->select(sqlString, (), medProviderID);


    match ret {
        table dataTable => {
            // Convert the sql data table into JSON using type conversion
            jsonReturnValue = check <json>dataTable;
            foreach b in jsonReturnValue[1].medName  {
                io:println(b);
            }
            int ndd = check <int> jsonReturnValue[0].medID;
            io:println(ndd);





        }
        error err => {
            jsonReturnValue = { "Status": "Data Not Found", "Error": err.message };

        }
    }
    return jsonReturnValue;
}