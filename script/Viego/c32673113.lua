--Erastin, the Ruined Dragon
local s,id=GetID()
function s.initial_effect(c)
    --synchro summon
    c:EnableReviveLimit()
    Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99,s.matfilter)
    --Special Material: Treat "Ruined" monster as Tuner
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetCondition(s.spcon)
    c:RegisterEffect(e0)
    --tribute to copy effects
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCost(s.copycost)
    e1:SetOperation(s.copyop)
    c:RegisterEffect(e1)
end
--Special Material handling
function s.matfilter(c,scard,sumtype,tp)
    return c:IsSetCard(0x35b)
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end
function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckReleaseGroupCost(tp,Card.IsSetCard,1,false,nil,e:GetHandler(),0x35b) end
    local g=Duel.SelectReleaseGroupCost(tp,Card.IsSetCard,1,1,false,nil,e:GetHandler(),0x35b)
    e:SetLabelObject(g:GetFirst())
    Duel.Release(g,REASON_COST)
end

function s.copyop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=e:GetLabelObject()
    if c:IsRelateToEffect(e) and c:IsFaceup() and tc then
        local code=tc:GetOriginalCode()
        c:CopyEffect(code,RESET_EVENT+RESETS_STANDARD+RESET_PHASE,1)
    end
end
