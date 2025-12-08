local ReGui = { };

local InsertService = Game:GetService("InsertService");
local Players = Game:GetService("Players");
local HttpService = Game:GetService("HttpService");

function ReGui:GetLatestVersion()
    local File = "https://github.com/depthso/Dear-ReGui/releases/latest/download/ReGui.rbxm";
    local Response = http.request({
        Url = File,
        Method = "GET",
    });

    if Response.Success then
        return Response.Body;
    end;
end;

function ReGui:Download()
    local Binary = self:GetLatestVersion();

    if not Binary then
        return;
    end;

    makefolder("ReGui");
    writefile("ReGui/File.rbxm", Binary);
    task.delay(1, delfolder, "ReGui");

    return getcustomasset("ReGui/File.rbxm");
end;

function ReGui:Load()
    local AssetId = self:Download();
    local Asset = getobjects(AssetId)[1];

    return loadstring(Asset.Source)();
end;

return ReGui;
