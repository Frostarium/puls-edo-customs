--Futile Engine Y
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Copy from hand/GY when opponent activates hand effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetHintTiming(0,TIMING_MAIN_END|TIMINGS_CHECK_MONSTER)
	e2:SetCountLimit(1,id)
	e2:SetCondition(function(e,tp) return Duel.GetCustomActivityCount(id,1-tp,ACTIVITY_CHAIN)>0 
		or Duel.GetFlagEffect(1-tp,id)>0 end)
	e2:SetTarget(s.copytg)
	e2:SetOperation(s.copyop)
	c:RegisterEffect(e2)
	Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,s.chainfilter)
	--Copy from Extra Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMING_END_PHASE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.spcon)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	--Track card additions
	local ge1=Effect.CreateEffect(c)
	ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ge1:SetCode(EVENT_TO_HAND)
	ge1:SetOperation(s.checkop)
	Duel.RegisterEffect(ge1,0)
end

function s.chainfilter(re,tp,cid)
    return not (re:GetActivateLocation()==LOCATION_HAND and re:IsMonsterEffect())
end

function s.checkop(e,tp,eg,ep,ev,re,r,rp)
    if not re or re:GetHandler():IsCode(id) then return end
    if ep~=tp and not Duel.GetCurrentPhase()==PHASE_DRAW then
        Duel.RegisterFlagEffect(ep,id,RESET_PHASE+PHASE_END,0,1)
    end
end

function s.copyfilter(c)
    return c:IsMonster() and c:IsFaceup()
end

function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and (Duel.IsExistingMatchingCard(s.copyfilter,tp,0,LOCATION_MZONE,1,nil)
        or Duel.IsExistingMatchingCard(s.copyfilter,tp,0,LOCATION_GRAVE,1,nil)) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.copyop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local g1=Duel.GetMatchingGroup(s.copyfilter,tp,0,LOCATION_MZONE,nil)
    local g2=Duel.GetMatchingGroup(s.copyfilter,tp,0,LOCATION_GRAVE,nil)
    if #g1<=0 and #g2<=0 then return end
    local sg=Group.CreateGroup()
    local b1=#g1>0
    local b2=#g2>0
    local op=Duel.SelectEffect(tp,
        {b1,aux.Stringid(id,2)},
        {b2,aux.Stringid(id,3)})
    if op==1 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
        sg=g1:Select(tp,1,1,nil)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
        sg=g2:Select(tp,1,1,nil)
    end
    if #sg>0 then
        local tc=sg:GetFirst()
        local token=Duel.CreateToken(tp,tc:GetCode())
        if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)~=0 then
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_SET_BASE_ATTACK)
            e1:SetValue(3000)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            token:RegisterEffect(e1)
            local e2=e1:Clone()
            e2:SetCode(EFFECT_SET_BASE_DEFENSE)
            token:RegisterEffect(e2)
        end
    end
end

function s.namefilter(c,code)
	return c:IsFaceup() and c:IsCode(code)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,nil)
	local checked={}
	for tc in aux.Next(g) do
		if not checked[tc:GetCode()] then
			checked[tc:GetCode()]=true
			local count=g:FilterCount(s.namefilter,nil,tc:GetCode())
			if count>=4 then return true end
		end
	end
	return false
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local g=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
    if #g>0 then
        Duel.ConfirmCards(tp,g)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local tc=g:Select(tp,1,1,nil):GetFirst()
        if tc then
            local token=Duel.CreateToken(tp,tc:GetCode())
            if Duel.SpecialSummon(token,0,tp,tp,true,true,POS_FACEUP)~=0 then
                if token:IsType(TYPE_XYZ) then
                    local mats=Group.CreateGroup()
                    for i=1,2 do
                        local mat=Duel.CreateToken(tp,token:GetCode())
                        if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT)~=0 then
                            mats:AddCard(mat)
                        end
                    end
                    if #mats>0 then
                        Duel.Overlay(token,mats)
                    end
                end
            end
        end
        Duel.ShuffleExtra(1-tp)
    end
end
