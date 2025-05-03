--Ledros, the Ruined King's Shield
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon this card
    local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,{id,1})
    e1:SetCondition(s.selfspcon) 
    e1:SetTarget(s.selfsptg)
    e1:SetOperation(s.selfspop)
	c:RegisterEffect(e1)

     --Cannot be destroyed
     local e2=Effect.CreateEffect(c)
     e2:SetType(EFFECT_TYPE_FIELD)
     e2:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
     e2:SetRange(LOCATION_MZONE)
     e2:SetTargetRange(LOCATION_MZONE,0)
     e2:SetTarget(s.indtg)
     e2:SetValue(s.indct)
     c:RegisterEffect(e2)
end
function s.selfspcon(e,tp,eg,ep,ev,re,r,rp)
	local ch=ev-1
	if ch==0 or ep==tp then return false end
	local ch_player,ch_eff=Duel.GetChainInfo(ch,CHAININFO_TRIGGERING_PLAYER,CHAININFO_TRIGGERING_EFFECT)
	local ch_c=ch_eff:GetHandler()
	return ch_player==tp and (ch_c:IsSetCard(0x35b) and not ch_c:IsCode(id))
		end
function s.selfsptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
end
function s.selfspop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        Duel.NegateEffect(ev)
    end
end
function s.indtg(e,c)
    return c:IsSetCard(0x35b)
end

function s.indct(e,re,r,rp)
    if (r&REASON_BATTLE+REASON_EFFECT)~=0 then
        return 1
    else 
        return 0 
    end
end

