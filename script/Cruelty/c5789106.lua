--Cruel Tangled Wasteland
local s,id=GetID()
function s.initial_effect(c)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    --"Cruel" Ritual Monsters gain ATK
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(function(_,c) return c:IsSetCard(0x67e) and c:IsRitualMonster() end)
	e2:SetValue(function(_,c) return c:GetLevel()*500 end)
	c:RegisterEffect(e2)
    local e3=e2:Clone()
    --"Cruel" Ritual Monsters gain DEF
    e3:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e3)
    --When Ritual Summon Snipe Edeck
    local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_TOGRAVE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetCondition(s.descon)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_FZONE)
    e5:SetCountLimit(1,{id,2},EFFECT_COUNT_CODE_OATH+EFFECT_COUNT_CODE_DUEL)
    e5:SetCondition(s.lvl30bancon)
    e5:SetTarget(s.lvl3andbelowtg)
    e5:SetOperation(s.lvl3andbelowop)
    c:RegisterEffect(e5)
end
function s.desconfilter(c,tp)
	return c:IsFaceup() and c:IsRitualMonster() and c:IsControler(tp) and c:IsRitualSummoned()
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.desconfilter,1,nil,tp)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local ex=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
        return ex:GetCount()>0
    end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,1-tp,LOCATION_EXTRA)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local ex=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
    if ex:GetCount()==0 then return end
    local g=ex:RandomSelect(1-tp,1)
    local tc=g:GetFirst()
    if not tc then return end
    if tc:IsType(TYPE_LINK) then
        Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
        return
    end
    if Duel.SendtoGrave(tc,REASON_EFFECT)==0 then return end
    local lv=tc:GetLevel()
    local rk=tc:GetRank()
    local new_lv = lv > 0 and lv - 10 or 0
    local new_rk = rk > 0 and rk - 10 or 0
    if (lv > 0 and new_lv < 1) or (rk > 0 and new_rk < 1) then
        Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
    else
        if lv > 0 or tc:IsType(TYPE_XYZ) then
        local e1=Effect.CreateEffect(tc)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LEVEL)
		e1:SetValue(lv-10)
		tc:RegisterEffect(e1)
        if rk > 0 then local e2=e1:Clone()
        e2:SetCode(EFFECT_CHANGE_RANK)
        e2:SetValue(rk-10)
        tc:RegisterEffect(e2)
        end
    end
end
end

function s.ritualfilter(c)
	return c:IsFaceup() and c:IsRitualMonster()
end

function s.lvl30bancon(e,tp,eg,ep,ev,re,r,rp)
	--Check if ritual monster level sum exceeds 30
	local g=Duel.GetMatchingGroup(s.ritualfilter,tp,LOCATION_MZONE,0,nil)
	local lvsum=0
    for tc in aux.Next(g) do
		lvsum=lvsum+tc:GetLevel()
	end
	return lvsum>30
end

function s.lvl3andbelowfilter(c)
    local lv = c:GetLevel()
    local rk = c:GetRank()
    return c:IsMonster() and ((lv > 0 and lv <= 3) or (rk > 0 and rk <= 3))
end

function s.lvl3andbelowtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk == 0 then
        local g = Duel.GetMatchingGroup(s.lvl3andbelowfilter,tp,0, LOCATION_DECK+LOCATION_MZONE+LOCATION_GRAVE+LOCATION_EXTRA, 1,nil,tp)
        return g:GetCount() > 0
    end
    local g = Duel.GetMatchingGroup(s.lvl3andbelowfilter,tp,0, LOCATION_DECK+LOCATION_MZONE+LOCATION_GRAVE+LOCATION_EXTRA, 1,nil,tp)
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, g:GetCount(), 0, 0)
end

function s.lvl3andbelowop(e,tp,eg,ep,ev,re,r,rp)
    local g = Duel.GetMatchingGroup(s.lvl3andbelowfilter,tp,0, LOCATION_DECK+LOCATION_MZONE+LOCATION_GRAVE+LOCATION_EXTRA, 1,nil,tp)
    if g:GetCount() > 0 then
        Duel.Remove(g, POS_FACEDOWN, REASON_EFFECT)
    end
end