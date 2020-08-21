local SupportEntry = class( "DemocracyClass.Widget.SupportEntry", Widget )

function SupportEntry:init(icon_size, max_width)
    SupportEntry._base.init( self )

    self.spacing = 5

    -- self.max_width = max_width or 400
    self.icon_size = icon_size or 72
    
    self:SetWidth(max_width or 400)
    -- self.text_width = self.max_width - self.icon_size - self.spacing * 3 -- - 10 - SPACING.M1*2

    self.hitbox = self:AddChild( Widget.SolidBox( 100, 100, 0xffff0030 ) )
        :SetTintAlpha( 0 )

    self.background = self:AddChild( Widget.Panel( engine.asset.Texture("UI/left_border_frame_faint.tex" ) ) )
        :SetBloom( 0.15 )

    self.icon = self:AddChild(Widget.Image())
        :SetSize(self.icon_size, self.icon_size)
        :SetBloom(0.1)
        -- :SetTexture(icon)
        -- :SetShown(icon ~= nil)
        -- :LayoutBounds("left", "center", 0, 0)
    -- self.details = self:AddChild(Widget())
        --:SetSize(self.text_width, self.icon_size)

    self.text = self:AddChild( Widget.Label("body", 50 ))
        :SetGlyphColour( UICOLOURS.SUBTITLE )
        :SetTintAlpha( 0.8 )
        :Bloom(0.05)
        :SetAutoSize( self.text_width )
        :LeftAlign()
        -- :LayoutBounds("left", "center", 144, 0)

    self:Refresh()
end

function SupportEntry:SetIcon(icon)
    self.icon:SetTexture(icon)
    return self
end

function SupportEntry:SetText(text)
    self.text:SetText(text)
    self:Layout()
    return self
end
function SupportEntry:SetWidth(width)
    self.max_width = width
    self.text_width = self.max_width - self.icon_size - self.spacing * 3
    return self
end

function SupportEntry:SetTextWidth(width)
    self.text_width = width
    self.max_width = self.text_width + self.icon_size + self.spacing * 3
    return self
end

function SupportEntry:GetSize()
    return self.hitbox:GetSize()
end
-- Just so things don't break
function SupportEntry:Refresh()
    local sizew, sizeh = self.icon:GetSize()

    local textw, texth = self.text:GetSize()

    if textw > self.text_width then
        self:SetTextWidth(textw)
    end
    
    self.hitbox:SetSize(self.max_width, sizeh + self.spacing * 2)
    self.background:SetSize(self.max_width, sizeh + self.spacing * 2)

    return self:Layout()
end

function SupportEntry:Layout()
    

    self.icon:LayoutBounds("left", "top"):Offset(self.spacing, -self.spacing)
    -- self.details:LayoutBounds("after","center")--:SetAutoSize( self.text_width ):LayoutBounds("after", "center")
    -- print(self.text.text)
    self.text:LayoutBounds("after","center", self.icon):Offset(self.spacing, 0)
    return self
end

function SupportEntry:SetColour(color)
    self.background:SetTintColour( color )
    self.text:SetGlyphColour( color )
    return self
end


local FactionSupportEntry = class( "DemocracyClass.Widget.FactionSupportEntry", DemocracyClass.Widget.SupportEntry )

function FactionSupportEntry:init(faction, icon_size, max_width)
    FactionSupportEntry._base.init(self, icon_size, max_width)

    if type(faction) == "string" then
        self.faction = TheGame:GetGameState():GetFaction(faction)
    else
        self.faction = faction
    end

    self:Refresh()
end

function FactionSupportEntry:Refresh()
    if self.faction then
        self:SetIcon(self.faction:GetIcon())
        self:SetText(
            loc.format("{1#faction}: {2}", 
                self.faction, 
                TheGame:GetGameState():GetMainQuest():DefFn("GetFactionSupport", self.faction.id)
            )
        )
        if self.faction:GetColour() then
            self:SetColour(self.faction:GetColour())
        end
    end
    return FactionSupportEntry._base.Refresh(self)
end