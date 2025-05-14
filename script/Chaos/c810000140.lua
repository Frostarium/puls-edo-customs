--Feral Chaos
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    --Cannot be Special Summoned except by own condition
    local e1=Effect.CreateEffect(c)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    e1:SetValue(s.splimit)
    c:RegisterEffect(e1)
	Fusion.AddProcMix(c,true,true,810000144,810000143)
    --Add contact fusion procedure
    Fusion.AddContactProc(c,s.contactfil,s.contactop,s.splimit,s.spcon)
    
	--Register summon activity
    aux.GlobalCheck(s,function()
        local ge1=Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
        ge1:SetOperation(s.regop)
        Duel.RegisterEffect(ge1,0)
    end)
        
    --Unaffected by other card effects
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EFFECT_IMMUNE_EFFECT)
    e3:SetValue(s.efilter)
    c:RegisterEffect(e3)
    
    --Banish all cards
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e4:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e4:SetCountLimit(1)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTarget(s.bantg)
    e4:SetOperation(s.banop)
    c:RegisterEffect(e4)
end

function s.reg(c)
    if c:IsCode(810000143) then
        Duel.RegisterFlagEffect(c:GetControler(),id,0,0,0)
    elseif c:IsCode(810000144) then
        Duel.RegisterFlagEffect(c:GetControler(),id+1,0,0,0)
    end
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	eg:ForEach(s.reg)
end

function s.efilter(e,te)
    return te:GetOwner()~=e:GetOwner()
end


function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA+LOCATION_ONFIELD+LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA+LOCATION_ONFIELD+LOCATION_GRAVE)
    if Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)>0 then
        Duel.Draw(1-tp,1,REASON_EFFECT)
    end
end

function s.splimit(e,se,sp,st)
    return e:GetHandler():GetLocation()~=LOCATION_EXTRA
end

function s.contactfil(tp)
    return Duel.GetMatchingGroup(Card.IsAbleToRemoveAsCost,tp,LOCATION_MZONE,0,nil)
end

function s.contactop(g)
    Duel.Remove(g,POS_FACEUP,REASON_COST|REASON_MATERIAL)
end

function s.spcon(tp)
    return Duel.GetFlagEffect(tp,id)+Duel.GetFlagEffect(tp,id+1)>=6
end