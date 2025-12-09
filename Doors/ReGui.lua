local ReGui = { };

function ReGui:GetModelBinary(file)
    local Response = http.request({
        Url = string.format("https://github.com/depthso/Dear-ReGui/releases/latest/download/%s", file),
        Method = "GET",
    });

    if not Response.Success then
        return;
    end;

    return Response.Body;
end;

function ReGui:GetAssetId()
    local AssetId = "";
    local Binary = self:GetModelBinary("ReGui.rbxm");
    local Hash = crypt.hash(tostring(math.random()), "sha256");

    if not (Binary and Hash) then
        return;
    end;

    writefile(Hash, Binary);
    AssetId = getcustomasset(Hash);
    delfile(Hash);

    return AssetId;
end;

function ReGui:Init()
    local AssetId = self:GetAssetId();
    local Asset = rawget(getobjects(AssetId), 1);

    return loadstring(Asset.Source)();
end;

return ReGui:Init();
