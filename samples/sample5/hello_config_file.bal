import ballerina/config;
import ballerina/http;
import ballerina/io;
import ballerinax/docker;

@docker:Config {}
@docker:CopyFiles{
    files:[
            {source:"./conf/ballerina.conf",target:"/home/ballerina/conf/ballerina.conf",isBallerinaConf:true},
            {source:"./conf/data.txt", target:"/home/ballerina/data/data.txt"}
          ]
}

@docker:Expose{}
endpoint http:Listener helloWorldEP {
    port:9090
};

@http:ServiceConfig {
      basePath:"/helloWorld"
}
service<http:Service> helloWorld bind helloWorldEP {
  	@http:ResourceConfig {
        methods:["GET"],
        path:"/config/{user}"
    }
    getConfig (endpoint outboundEP, http:Request request,string user) {
        http:Response response = new;
        string userId = getConfigValue(user, "userid");
        string groups = getConfigValue(user, "groups");
        string payload = "{userId: "+userId+", groups: "+groups+"}";
        response.setStringPayload(payload +"\n");
        _ = outboundEP -> respond(response);
    }
    @http:ResourceConfig {
        methods:["GET"],
        path:"/data"
    }
    getData (endpoint outboundEP, http:Request request) {
        http:Response response = new;
        string payload = readFile("./data/data.txt", "r", "UTF-8");
        response.setStringPayload("Data: "+ payload +"\n");
        _ = outboundEP -> respond(response);
    }
}

function getConfigValue (string instanceId, string property) returns (string) {
    string key = untaint instanceId + "." + untaint property;
    return config:getAsString(key, default = "Invalid User");
}

function readFile (string filePath, string permission, string encoding) returns (string) {
    io:ByteChannel channel = io:openFile(filePath, permission);
    var characterChannelResult = io:createCharacterChannel(channel, encoding);
    io:CharacterChannel sourceChannel = new;
    match characterChannelResult {  
        (io:CharacterChannel) res => {
            sourceChannel = res;
        }
        error err => {
            io:println(err);
        }
    }
    var contentResult = sourceChannel.readCharacters(50);
    match contentResult {
        (string) res => {
            return res;
        }
        error err => {
            io:println(err);
            return err.message;
        }
    }    
}

