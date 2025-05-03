--S.S.0 - Star Signis Zero
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    --Xyz Summon Procedure
    Xyz.AddProcedure(c,nil,6,2,s.ovfilter,aux.Stringid(id,0))
    -- Attach 1 card from either field or graveyard to this card as material
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,2))
    e1:SetCategory(CATEGORY_LEAVE_GRAVE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1,{id,1})
    e1:SetRange(LOCATION_MZONE)
    e1:SetTarget(s.attachtg)
    e1:SetOperation(s.attachop)
    c:RegisterEffect(e1)
    -- Detach all materials to banish this card until the end phase and special summon detached monsters
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,3))
    e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,2})
    e2:SetCost(s.bancost)
    e2:SetTarget(s.bantg)
    e2:SetOperation(s.banop)
    c:RegisterEffect(e2)
end

function s.bancost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():GetOverlayCount()>0 end
end

function s.spfilter(c,e,tp)
    return c:IsLocation(LOCATION_GRAVE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemove() 
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,0,0)
    local g=e:GetHandler():GetOverlayGroup()
    if #g>0 then
        Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,#g,tp,LOCATION_GRAVE)
    end
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local mg=c:GetOverlayGroup()
    if #mg>0 then
        Duel.SendtoGrave(mg,REASON_EFFECT)
    end
    Duel.AdjustInstantly(c)
    
    if Duel.Remove(c,POS_FACEUP,REASON_EFFECT+REASON_TEMPORARY)~=0 then
        local g=mg:Filter(s.spfilter,nil,e,tp)
        local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
        if ft>0 and #g>0 then
            if ft>#g then ft=#g end
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sg=g:Select(tp,ft,ft,nil)
            Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
        end
        
        --Return effect
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_PHASE+PHASE_END)
        e1:SetReset(RESET_PHASE+PHASE_END)
        e1:SetLabelObject(c)
        e1:SetCountLimit(1)
        e1:SetOperation(s.retop)
        Duel.RegisterEffect(e1,tp)
        c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
    end
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetLabelObject()
    if c:GetFlagEffect(id)~=0 then
        Duel.ReturnToField(c)
    end
end

function s.ovfilter(c,tp,xyzc)
    return c:IsFaceup() and c:IsSetCard(0xbbb,xyzc,SUMMON_TYPE_XYZ,tp) and c:IsLevel(8)
end

function s.attachfilter0(c,xyzc,tp)
    return c:IsCanBeXyzMaterial(xyzc,tp,REASON_EFFECT) and c~=xyzc and not c:IsCode(id)
end

function s.attachtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_ONFIELD) and s.attachfilter0(chkc,e:GetHandler(),tp) end
    if chk==0 then return Duel.IsExistingTarget(s.attachfilter0,tp,LOCATION_GRAVE+LOCATION_ONFIELD,LOCATION_GRAVE+LOCATION_ONFIELD,1,nil,e:GetHandler(),tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    local g=Duel.SelectTarget(tp,s.attachfilter0,tp,LOCATION_GRAVE+LOCATION_ONFIELD,LOCATION_GRAVE+LOCATION_ONFIELD,1,1,nil,e:GetHandler(),tp)
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
    
end
function s.attachop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and c:IsRelateToEffect(e) then
        Duel.Overlay(c,tc)
    end
end
