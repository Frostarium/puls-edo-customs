--Amalgamation of Ruined Souls, Rhasa
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon procedure: 2+ Level 6 monsters
	Xyz.AddProcedure(c,nil,9,2,nil,nil,Xyz.InfiniteMats)
	--Treat 1 Ruined monster you control as level 9 for Xyz Summon
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_XYZ_LEVEL)
	e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(e,c) return c:HasLevel() and c:IsSetCard(0x35b) end)
	e1:SetValue(s.lvval)
	c:RegisterEffect(e1)
	
	--Cannot be destroyed by card effects while it has materials
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetCondition(function(e) return e:GetHandler():GetOverlayCount()>0 end)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	
	--Attach a Ruined monster as material
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.mattg)
	e3:SetOperation(s.matop)
	c:RegisterEffect(e3)

	--Send cards to GY by detaching materials
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOGRAVE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetTarget(s.tgtg)
	e4:SetOperation(s.tgop)
	c:RegisterEffect(e4)
end

function s.lvval(e,c,rc)
	local lv=c:GetLevel()
	if rc:IsCode(id) then
		return 9
	else
		return lv
	end
end

function s.matfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x35b) and c:IsType(TYPE_MONSTER)
end

function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chk==0 then return Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,e:GetHandler()) end
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    local g=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,c)
    if #g>0 then
        Duel.Overlay(c,g)
    end
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():GetOverlayCount()>0 
        and Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,0,LOCATION_ONFIELD,1,nil) end
    local oc=e:GetHandler():GetOverlayCount()
    local max=math.min(oc,Duel.GetFieldGroupCount(tp,0,LOCATION_ONFIELD))
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,1-tp,LOCATION_ONFIELD)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local oc=c:GetOverlayCount()
    local max=math.min(oc,Duel.GetFieldGroupCount(tp,0,LOCATION_ONFIELD))
    local ct=Duel.AnnounceNumber(tp,1,max)
    if c:RemoveOverlayCard(tp,ct,ct,REASON_EFFECT) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local g=Duel.SelectMatchingCard(tp,Card.IsAbleToGrave,tp,0,LOCATION_ONFIELD,ct,ct,nil)
        if #g>0 then
            Duel.SendtoGrave(g,REASON_EFFECT)
        end
    end
end